import { EntryError } from "./util.mjs";

export const LIMITS = { files: 300, fileBytes: 2 * 1024 * 1024, totalBytes: 20 * 1024 * 1024 };

const ID = /^[a-z0-9][a-z0-9-]{1,62}$/;
const COMMIT = /^[0-9a-f]{40}$/;
const REPO = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const KEYS = ["title", "description", "author", "source", "entry", "paths", "add", "packages", "level"];

function text(value, what, max) {
  if (typeof value !== "string" || !value.trim()) throw new EntryError(`${what} must be a non-empty string`);
  if (value.length > max) throw new EntryError(`${what} is longer than ${max} characters`);
  if (/[\u0000-\u0008\u000b\u000c\u000e-\u001f]/.test(value)) throw new EntryError(`${what} has control characters`);
  return value;
}

/** A title or description: {"en": "...", "zh": "..."}, with `en` required; other codes are optional. */
function texts(value, what, max) {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new EntryError(`${what} must be an object with "en"`);
  if (!("en" in value)) throw new EntryError(`${what} needs an "en" text`);
  for (const [code, t] of Object.entries(value)) {
    if (!/^[a-z]{2,3}(-[A-Za-z0-9]+)?$/.test(code)) throw new EntryError(`${what}: "${code}" is not a language code`);
    text(t, `${what}.${code}`, max);
  }
  return value;
}

/** A path inside a repository: relative, with no `..`, no backslash, no leading slash. */
export function repoPath(value, what, { dir = false } = {}) {
  text(value, what, 300);
  if (value.startsWith("/") || value.includes("\\") || value.split("/").some((part) => part === ".." || part === ".")) {
    throw new EntryError(`${what}: "${value}" must be a relative path without "." or ".."`);
  }
  if (dir && value.endsWith("/")) return value.replace(/\/+$/, "");
  if (value.endsWith("/")) throw new EntryError(`${what}: "${value}" names a directory`);
  return value;
}

/** Check an entry's JSON and return it. `id` is the file name without `.json`. */
export function validateEntry(id, entry) {
  if (!ID.test(id)) throw new EntryError(`the file name "${id}.json" is not a valid id (lower case letters, digits and hyphens, 2 to 63 characters)`);
  if (!entry || typeof entry !== "object" || Array.isArray(entry)) throw new EntryError("an entry is a JSON object");
  for (const key of Object.keys(entry)) if (!KEYS.includes(key)) throw new EntryError(`unknown field "${key}"`);
  texts(entry.title, "title", 80);
  texts(entry.description, "description", 400);
  text(entry.author, "author", 80);
  if (entry.source !== undefined) {
    const source = entry.source;
    if (!source || typeof source !== "object") throw new EntryError("source must be {repo, commit}");
    for (const key of Object.keys(source)) if (!["repo", "commit"].includes(key)) throw new EntryError(`unknown field "source.${key}"`);
    if (typeof source.repo !== "string" || !REPO.test(source.repo)) throw new EntryError('source.repo must be "owner/name" on GitHub');
    if (typeof source.commit !== "string" || !COMMIT.test(source.commit)) throw new EntryError("source.commit must be the full 40-digit commit id, not a branch or a tag");
  }
  repoPath(entry.entry, "entry");
  if (!/\.(sp|spi|cir|net|scs)$/i.test(entry.entry)) throw new EntryError("entry must be a SPICE (.sp, .spi, .cir, .net) or Spectre (.scs) netlist");
  for (const key of ["paths", "add"]) {
    if (entry[key] === undefined) continue;
    if (!Array.isArray(entry[key]) || entry[key].length > 50) throw new EntryError(`${key} must be a list of at most 50 paths`);
    entry[key].forEach((p, i) => repoPath(p, `${key}[${i}]`, { dir: true }));
  }
  if (entry.packages !== undefined) {
    if (!Array.isArray(entry.packages) || entry.packages.length > 20) throw new EntryError("packages must be a list of at most 20");
    entry.packages.forEach((p, i) => {
      const what = `packages[${i}]`;
      const kinds = ["name", "path", "url"].filter((k) => k in p);
      if (kinds.length !== 1) throw new EntryError(`${what} is {"name", "version"}, {"path"} or {"url"}`);
      if (kinds[0] === "name") {
        text(p.name, `${what}.name`, 80);
        text(p.version, `${what}.version`, 40);
        if (Object.keys(p).length !== 2) throw new EntryError(`${what}: a package from the catalog is {"name", "version"}`);
      } else if (kinds[0] === "path") {
        repoPath(p.path, `${what}.path`);
        if (Object.keys(p).length !== 1) throw new EntryError(`${what}: only "path"`);
      } else {
        if (!/^https:\/\/raw\.githubusercontent\.com\/[^\s]+$/.test(p.url)) throw new EntryError(`${what}.url must be a raw.githubusercontent.com address`);
        if (Object.keys(p).length !== 1) throw new EntryError(`${what}: only "url"`);
      }
    });
  }
  if (entry.level !== undefined) text(entry.level, "level", 200);
  return entry;
}
