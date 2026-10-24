#!/usr/bin/env node
// Reads entries/*.json, resolves each one against its source, and writes what the site reads into dist/:
//   index.json, manifests/<id>.json and thumbs/<id>.<hash>.png.
// usage: node tools/build.mjs [--out DIR] [--only id,id] [--entries DIR]
import { existsSync, readdirSync, readFileSync, writeFileSync, mkdirSync, rmSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import { startCore } from "@rich-netlist/runtime";
import { validateEntry } from "./lib/entry.mjs";
import { openSource } from "./lib/sources.mjs";
import { resolveEntry } from "./lib/resolve.mjs";
import { thumbnail } from "./lib/thumb.mjs";
import { ensureFonts } from "./fonts.mjs";
import { EntryError } from "./lib/util.mjs";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const args = process.argv.slice(2);
const option = (name, fallback) => { const i = args.indexOf(name); return i >= 0 ? args[i + 1] : fallback; };
const outDir = resolve(option("--out", join(root, "dist")));
const entriesDir = resolve(option("--entries", join(root, "entries")));
const only = option("--only") ? option("--only").split(",").filter(Boolean) : null;

const selfCommit = process.env.GITHUB_SHA || (() => {
  try { return execFileSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" }).trim(); } catch { return undefined; }
})();

const ids = (existsSync(entriesDir) ? readdirSync(entriesDir) : []).filter((f) => f.endsWith(".json")).map((f) => f.slice(0, -5)).sort();
const wanted = only ?? ids;
for (const id of wanted) if (!ids.includes(id)) { console.error(`no entry ${id}`); process.exit(2); }

const fonts = await ensureFonts();
const core = startCore();
rmSync(outDir, { recursive: true, force: true });
for (const dir of ["manifests", "thumbs"]) mkdirSync(join(outDir, dir), { recursive: true });

const index = [];
const failures = [];
for (const id of wanted) {
  const started = performance.now();
  const file = `entries/${id}.json`;
  try {
    let entry;
    try { entry = JSON.parse(readFileSync(join(entriesDir, `${id}.json`), "utf8")); } catch (e) { throw new EntryError(`not valid JSON: ${e.message}`); }
    validateEntry(id, entry);
    const source = openSource(id, entry, { selfCommit });
    const { manifest, level, warnings } = await resolveEntry(id, entry, source, { core });
    const thumb = thumbnail(level.svg, fonts);
    const thumbPath = `thumbs/${id}.${thumb.hash}.png`;
    writeFileSync(join(outDir, thumbPath), thumb.png);
    writeFileSync(join(outDir, "manifests", `${id}.json`), JSON.stringify(manifest, null, 2) + "\n");
    index.push({
      id,
      title: manifest.title,
      description: manifest.description,
      author: manifest.author,
      license: manifest.license,
      source: { repo: manifest.source.repo, commit: manifest.source.commit, url: manifest.source.url },
      files: manifest.files.length,
      viewer: manifest.files.length === 1 ? { url: manifest.base + manifest.entry } : { manifest: `manifests/${id}.json` },
      thumb: { path: thumbPath, width: thumb.width, height: thumb.height },
    });
    console.log(`ok   ${id}: ${manifest.files.length} files, level "${manifest.level}", thumbnail ${thumb.png.length} bytes, ${Math.round(performance.now() - started)} ms`);
    for (const w of warnings.slice(0, 5)) console.log(`::warning file=${file}::${w.replaceAll("\n", " ")}`);
  } catch (error) {
    const message = error instanceof EntryError ? error.message : `${error.stack ?? error}`;
    failures.push({ id, message });
    console.log(`FAIL ${id}`);
    console.log(`::error file=${file}::${message.replaceAll("\n", "%0A")}`);
    console.log(message.split("\n").map((l) => `     ${l}`).join("\n"));
  }
}
core.terminate();

writeFileSync(join(outDir, "index.json"), JSON.stringify({ format: 1, generated: new Date().toISOString(), entries: index }, null, 2) + "\n");
writeFileSync(join(outDir, ".nojekyll"), "");
writeFileSync(join(outDir, "index.html"), `<!doctype html><meta charset="utf-8"><title>RNL gallery data</title><p>Data for the <a href="https://rich-netlist.github.io/rnl/gallery.html">RNL gallery</a>: <a href="index.json">index.json</a>. Source: <a href="https://github.com/rich-netlist/rnl-gallery">rich-netlist/rnl-gallery</a>.</p>\n`);
if (failures.length) {
  console.error(`\n${failures.length} of ${wanted.length} entries failed: ${failures.map((f) => f.id).join(", ")}`);
  process.exit(1);
}
console.log(`\n${index.length} entries written to ${outDir}`);
