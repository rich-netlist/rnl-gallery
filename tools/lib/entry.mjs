import { EntryError } from "./util.mjs";
import { ALLOWED } from "./license.mjs";

export const LIMITS = { files: 300, fileBytes: 2 * 1024 * 1024, totalBytes: 20 * 1024 * 1024 };

const ID = /^[a-z0-9][a-z0-9-]{1,62}$/;
const COMMIT = /^[0-9a-f]{40}$/;
const REPO = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const KEYS = ["title", "description", "author", "license", "tags", "source", "entry", "paths", "add", "packages", "formats", "level", "cover"];
// A tag is written as it is to be shown ("180nm CMOS", "PLL"): letters, digits, single spaces and - . + /, 1 to 32 characters.
const TAG = /^[A-Za-z0-9](?:[A-Za-z0-9.+/-]| (?! ))*$/;

/** What tags are compared by, in the gallery's filter and addresses: lower case, with hyphens for spaces. */
export const tagKey = (tag) => tag.toLowerCase().replace(/ /g, "-");

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

/** The authors: a name, or a list of {"name", "url"} (the link is optional and has to be https). */
export function authors(value) {
  if (typeof value === "string") { text(value, "author", 80); return; }
  if (!Array.isArray(value) || value.length < 1 || value.length > 8) throw new EntryError('author is a name, or a list of 1 to 8 {"name", "url"}');
  value.forEach((a, i) => {
    const what = `author[${i}]`;
    if (!a || typeof a !== "object" || Array.isArray(a)) throw new EntryError(`${what} is {"name": …, "url": …}`);
    for (const key of Object.keys(a)) if (!["name", "url"].includes(key)) throw new EntryError(`unknown field "${what}.${key}"`);
    text(a.name, `${what}.name`, 80);
    if (a.url !== undefined && !/^https:\/\/[^\s"<>]+$/.test(a.url)) throw new EntryError(`${what}.url must be an https address`);
  });
}

/** The authors of an entry as a list of {name, url?}, which is how the manifest and the index give them. */
export function authorList(value) {
  return typeof value === "string" ? [{ name: value }] : value.map((a) => ({ name: a.name, ...(a.url ? { url: a.url } : {}) }));
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
  authors(entry.author);
  if (entry.license !== undefined && !ALLOWED.includes(entry.license)) throw new EntryError(`license "${entry.license}" is not an accepted SPDX id (${ALLOWED.join(", ")})`);
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
  if (entry.formats !== undefined) {
    const formats = entry.formats;
    if (!formats || typeof formats !== "object" || Array.isArray(formats)) throw new EntryError('formats is {"path": "spice" | "spectre", …}: the files that have to be told how to be read');
    const paths = Object.keys(formats);
    if (paths.length > 50) throw new EntryError("formats names at most 50 files");
    for (const path of paths) {
      repoPath(path, `formats["${path}"]`);
      text(formats[path], `formats["${path}"]`, 32);
    }
  }
  if (entry.level !== undefined) text(entry.level, "level", 200);
  if (entry.cover !== undefined) {
    const cover = entry.cover;
    if (entry.level !== undefined) throw new EntryError('give "cover" or "level", not both: {"level": X} is {"cover": {"cell": X}}');
    if (!cover || typeof cover !== "object" || Array.isArray(cover)) throw new EntryError('cover is {"cell": …, "view": "schematic" | "symbol"}');
    for (const key of Object.keys(cover)) if (!["cell", "view"].includes(key)) throw new EntryError(`unknown field "cover.${key}"`);
    if (cover.cell !== undefined) text(cover.cell, "cover.cell", 200);
    if (cover.view !== undefined && !["schematic", "symbol"].includes(cover.view)) throw new EntryError('cover.view is "schematic" or "symbol"');
    if (cover.view === "symbol" && (cover.cell === undefined || cover.cell === "(top)")) throw new EntryError("the symbol of a cell needs the cell: a subcircuit name");
  }
  if (entry.tags !== undefined) {
    if (!Array.isArray(entry.tags) || entry.tags.length > 8) throw new EntryError("tags is a list of at most 8 tags");
    for (const tag of entry.tags) {
      if (typeof tag !== "string" || tag.length > 32 || !TAG.test(tag) || tag.endsWith(" ")) throw new EntryError(`tag "${tag}": letters, digits, single spaces and - . + /, at most 32 characters, written as it is to be shown`);
    }
    if (new Set(entry.tags.map(tagKey)).size !== entry.tags.length) throw new EntryError("a tag is given twice (tags are compared without regard to case, and a space is a hyphen)");
  }
  return entry;
}
