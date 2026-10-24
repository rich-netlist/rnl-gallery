import { posix } from "node:path";
import { collect, decodeText } from "@rich-netlist/runtime";
import { sha256, mapLimit, fetchRetry, EntryError } from "./util.mjs";
import { repoPath, LIMITS } from "./entry.mjs";
import { checkLicense } from "./license.mjs";

/** Where the files of an entry sit in the workspace the core reads. The manifest itself has paths without it. */
export const ROOT = "/w/";
const NET_EXT = /\.(sp|spi|cir|net|scs|inc|lib|rnl)$/i;
const PACKAGE = /\.rnl$/i;
const NOTHING = "(nothing is drawn)";
const CATALOG = process.env.RNL_PACKAGE_CATALOG || "https://rich-netlist.github.io/rnl-packages/catalog.json";

const dirOf = (path) => (posix.dirname(path) === "." ? "" : posix.dirname(path));
const strip = (path) => path.replace(/\/+$/, "");

/** A package of the public catalog, as a file: its address, the bytes, and the SHA-256 the catalog gives. */
async function catalogPackage(name, version) {
  const text = /^https?:/.test(CATALOG) ? await (await fetchRetry(CATALOG)).text() : (await import("node:fs")).readFileSync(CATALOG, "utf8");
  const catalog = JSON.parse(text);
  if (catalog.schemaVersion !== 1) throw new Error("the package catalog has an unsupported schema");
  const pkg = catalog.packages.find((p) => p.name === name && p.version === version);
  if (!pkg) throw new EntryError(`the public package catalog has no ${name} ${version}`);
  const url = new URL(pkg.url, CATALOG).href;
  let bytes;
  if (/^https?:/.test(url)) {
    const response = await fetchRetry(url);
    if (!response.ok) throw new Error(`${url}: HTTP ${response.status}`);
    bytes = Buffer.from(await response.arrayBuffer());
  } else {
    bytes = (await import("node:fs")).readFileSync(new URL(url));
  }
  if (sha256(bytes) !== pkg.sha256) throw new Error(`${name} ${version}: the downloaded file does not match the catalog's SHA-256`);
  return { url, bytes };
}

async function urlPackage(url) {
  const response = await fetchRetry(url);
  if (!response.ok) throw new EntryError(`${url}: HTTP ${response.status}`);
  return Buffer.from(await response.arrayBuffer());
}

/**
 * Turn an entry into what is needed to open it: the manifest, the Document the core builds from exactly the files
 * the manifest lists (checked to be what it builds from all the candidates), and the level to draw.
 */
export async function resolveEntry(id, entry, source, { core }) {
  const spdx = await source.license();
  const licenseProblem = checkLicense(spdx);
  if (licenseProblem) throw new EntryError(`${source.repo}: ${licenseProblem}`);

  const list = await source.list();
  const present = new Set(list);
  if (!present.has(entry.entry)) throw new EntryError(`entry "${entry.entry}" is not in ${source.repo} at ${source.commit.slice(0, 10)}${source.prefix ? ` under ${source.prefix}` : ""}`);

  const bytesOf = new Map(); // path -> {bytes, sha256}, from the source
  const virtual = new Map(); // paths that do not come from the source: package files
  const fetched = async (path) => {
    if (bytesOf.has(path)) return bytesOf.get(path);
    const bytes = await source.read(path);
    const got = bytes ? { bytes, sha256: sha256(bytes) } : null;
    bytesOf.set(path, got);
    return got;
  };

  // Candidates, in the order the core searches bare include names: the `paths` directories, then `add`.
  const pool = [];
  const explicit = new Set();
  const push = (path, keep) => { if (!pool.includes(path)) pool.push(path); if (keep) explicit.add(path); };
  for (const dir of (entry.paths ?? [dirOf(entry.entry)]).map(strip)) {
    const files = list.filter((f) => dirOf(f) === dir && NET_EXT.test(f));
    if (!files.length && entry.paths) throw new EntryError(`paths: "${dir}" has no netlist or package files`);
    files.forEach((f) => push(f, false));
  }
  for (const item of (entry.add ?? []).map(strip)) {
    const under = list.filter((f) => f.startsWith(`${item}/`) && NET_EXT.test(f));
    if (under.length) under.forEach((f) => push(f, true));
    else if (present.has(item)) push(item, true);
    else throw new EntryError(`add: "${item}" is not a file or a directory with netlists or packages`);
  }
  for (const p of entry.packages ?? []) {
    if (p.path) {
      repoPath(p.path, "packages.path");
      if (!present.has(p.path)) throw new EntryError(`packages: "${p.path}" is not in the repository`);
      push(p.path, true);
    } else {
      const file = p.name ? await catalogPackage(p.name, p.version) : { url: p.url, bytes: await urlPackage(p.url) };
      const path = `.packages/${p.name ? `${p.name}-${p.version}` : posix.basename(new URL(p.url).pathname).replace(/\.rnl$/i, "")}.rnl`;
      virtual.set(path, { bytes: file.bytes, sha256: sha256(file.bytes), url: file.url });
      push(path, true);
    }
  }
  if (pool.length > LIMITS.files) throw new EntryError(`more than ${LIMITS.files} candidate files; list fewer in "paths" and "add"`);
  push(entry.entry, false);

  const get = async (path) => virtual.get(path) ?? fetched(path);
  const missing = [];
  await mapLimit(pool, 8, async (path) => { if (!(await get(path))) missing.push(path); });
  if (missing.length) throw new EntryError(`not found: ${missing.join(", ")}`);
  const textOf = (path) => decodeText((virtual.get(path) ?? bytesOf.get(path)).bytes);

  const read = async (rooted) => {
    if (!rooted.startsWith(ROOT)) return null;
    const rel = posix.normalize(rooted.slice(ROOT.length));
    if (rel.startsWith("../") || rel === "..") return null;
    const got = await get(rel);
    if (!got) return null;
    used.add(rel);
    return decodeText(got.bytes);
  };
  const used = new Set();

  const orderedPool = pool.filter((p) => p !== entry.entry);
  const files = Object.fromEntries(pool.map((p) => [ROOT + p, textOf(p)]));
  const { document: full } = await collect(core, { entry: ROOT + entry.entry, files, pool: orderedPool.map((p) => ROOT + p) }, read);

  // What the build used: the host files the Document lists, what the reading provided, and what the entry names.
  const entryDir = posix.dirname(ROOT + entry.entry);
  for (const f of full.files ?? []) {
    const rooted = f.path.startsWith("/") ? f.path : posix.join(entryDir, f.path);
    if (rooted.startsWith(ROOT)) used.add(posix.normalize(rooted.slice(ROOT.length)));
  }
  explicit.forEach((p) => used.add(p));
  used.add(entry.entry);
  // A package found by name in the pool is not read by path, and no list says it was used: leave it out and see.
  const unsure = pool.filter((p) => PACKAGE.test(p) && !used.has(p));
  for (const p of unsure) {
    if (unsure.length > 20) { used.add(p); continue; }
    const without = await core.build({ entry: ROOT + entry.entry, files: Object.fromEntries(pool.filter((q) => q !== p).map((q) => [ROOT + q, textOf(q)])), pool: orderedPool.filter((q) => q !== p).map((q) => ROOT + q) });
    if (!sameDocument(without, full)) used.add(p);
  }
  const kept = [...used].filter((p) => bytesOf.get(p) || virtual.has(p));
  const keptPool = orderedPool.filter((p) => used.has(p));

  // Build again from exactly these files: it must give the Document the candidates gave.
  const request = { entry: ROOT + entry.entry, files: Object.fromEntries(kept.map((p) => [ROOT + p, textOf(p)])), pool: keptPool.map((p) => ROOT + p) };
  const document = await core.build(request);
  if (!sameDocument(document, full)) throw new Error(`${id}: the build from the listed files differs from the build from all the candidates`);

  if (document.failed) throw new EntryError(`the core cannot read it: ${document.failed}`);
  const errors = document.diagnostics.filter((d) => d.severity === "error");
  const describe = (d) => `${d.file}:${d.line ?? "?"} ${d.message}`;
  if (errors.length) throw new EntryError(`rnl check reports ${errors.length} error${errors.length === 1 ? "" : "s"}:\n  ${errors.slice(0, 8).map(describe).join("\n  ")}`);
  const warnings = document.diagnostics.filter((d) => d.severity === "warning").map(describe);

  const level = pickLevel(document, entry.level);

  const order = [entry.entry, ...kept.filter((p) => p !== entry.entry).sort()];
  const manifestFiles = order.map((path) => {
    const f = virtual.get(path) ?? bytesOf.get(path);
    if (f.bytes.length > LIMITS.fileBytes) throw new EntryError(`${path} is larger than ${LIMITS.fileBytes / 1048576} MB`);
    return { path, sha256: f.sha256, size: f.bytes.length, ...(virtual.has(path) ? { url: f.url } : {}) };
  });
  const total = manifestFiles.reduce((n, f) => n + f.size, 0);
  if (manifestFiles.length > LIMITS.files) throw new EntryError(`${manifestFiles.length} files: more than ${LIMITS.files}`);
  if (total > LIMITS.totalBytes) throw new EntryError(`${(total / 1048576).toFixed(1)} MB of files: more than ${LIMITS.totalBytes / 1048576} MB`);

  const manifest = {
    format: 1,
    id,
    title: entry.title,
    description: entry.description,
    author: entry.author,
    source: { repo: source.repo, commit: source.commit, url: source.htmlUrl },
    license: spdx,
    base: source.rawBase,
    entry: entry.entry,
    files: manifestFiles,
    pool: keptPool,
    level: level.kind === "file" ? "(top)" : level.title,
  };
  return { manifest, document, level, warnings, totalBytes: total };
}

/** Whether two builds drew the same levels and found the same problems. */
const sameDocument = (a, b) => a.missing.length === b.missing.length && a.diagnostics.length === b.diagnostics.length &&
  a.levels.length === b.levels.length && a.levels.every((l, i) => l.title === b.levels[i].title && l.svg === b.levels[i].svg);

/** The level the entry draws: its `level`, "(top)" for the file's own, else the first that draws something. */
export function pickLevel(document, want) {
  if (want === "(top)") return document.levels[0];
  if (want !== undefined) {
    const level = document.levels.find((l) => l.title === want);
    if (!level) throw new EntryError(`level "${want}" is not one of: ${document.levels.slice(0, 12).map((l) => l.title).join(", ")}${document.levels.length > 12 ? ", …" : ""}`);
    return level;
  }
  const level = document.levels.find((l) => l.svg && !l.svg.includes(NOTHING));
  if (!level) throw new EntryError("no level draws anything: the netlist has no positions (see the RNL guide), so there is nothing to show");
  return level;
}
