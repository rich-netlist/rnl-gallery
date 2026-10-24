import { readFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { fetchRetry, EntryError } from "./util.mjs";

export const SELF_REPO = "rich-netlist/rnl-gallery";

/**
 * Where an entry's files are: a GitHub repository at one commit, optionally below a directory (`prefix`, which is
 * how the official examples of this repository are addressed). `list()` gives the paths of the files under the
 * prefix, `read(path)` a file's bytes or null, `license()` the repository's SPDX id.
 */
export class GitHubSource {
  constructor({ repo, commit, prefix = "", token = process.env.GITHUB_TOKEN }) {
    Object.assign(this, { repo, commit, prefix, token, kind: "github" });
  }
  get rawBase() { return `https://raw.githubusercontent.com/${this.repo}/${this.commit}/${this.prefix}`; }
  get htmlUrl() { return `https://github.com/${this.repo}/tree/${this.commit}/${this.prefix}`.replace(/\/$/, ""); }
  api(path) {
    const headers = { accept: "application/vnd.github+json", "user-agent": "rnl-gallery" };
    if (this.token) headers.authorization = `Bearer ${this.token}`;
    return fetchRetry(`https://api.github.com/${path}`, { headers });
  }
  async list() {
    if (this._list) return this._list;
    const response = await this.api(`repos/${this.repo}/git/trees/${this.commit}?recursive=1`);
    if (response.status === 404) throw new EntryError(`${this.repo}: commit ${this.commit} not found (the repository must be public and the commit pushed)`);
    if (!response.ok) throw new Error(`${this.repo}: the file list gave HTTP ${response.status}`);
    const tree = await response.json();
    if (tree.truncated) throw new EntryError(`${this.repo}: the repository has too many files to list`);
    this._list = tree.tree.filter((n) => n.type === "blob" && n.path.startsWith(this.prefix)).map((n) => n.path.slice(this.prefix.length)).sort();
    return this._list;
  }
  async read(path) {
    const response = await fetchRetry(this.rawBase + path.split("/").map(encodeURIComponent).join("/"));
    if (response.status === 404) return null;
    if (!response.ok) throw new Error(`${this.rawBase}${path}: HTTP ${response.status}`);
    return Buffer.from(await response.arrayBuffer());
  }
  async license() {
    const response = await this.api(`repos/${this.repo}/license`);
    if (response.status === 404) return null;
    if (!response.ok) throw new Error(`${this.repo}: the licence gave HTTP ${response.status}`);
    return (await response.json()).license?.spdx_id ?? null;
  }
}

/** A directory standing in for a repository, for tests and for checking before a push. */
export class LocalSource {
  constructor({ repo, commit, prefix = "", dir, licenseId }) {
    Object.assign(this, { repo, commit, prefix, dir, licenseId, kind: "local" });
  }
  get rawBase() { return `https://raw.githubusercontent.com/${this.repo}/${this.commit}/${this.prefix}`; }
  get htmlUrl() { return `https://github.com/${this.repo}/tree/${this.commit}/${this.prefix}`.replace(/\/$/, ""); }
  async list() {
    const root = join(this.dir, this.prefix);
    const out = [];
    const walk = (d) => {
      for (const name of readdirSync(d).sort()) {
        if (name === ".git" || name === "node_modules") continue;
        const p = join(d, name);
        if (statSync(p).isDirectory()) walk(p); else out.push(relative(root, p).replaceAll("\\", "/"));
      }
    };
    if (existsSync(root)) walk(root);
    return out;
  }
  async read(path) {
    const p = join(this.dir, this.prefix, path);
    return existsSync(p) ? readFileSync(p) : null;
  }
  async license() { return this.licenseId ?? null; }
}

/**
 * The source of an entry. RNL_GALLERY_LOCAL is a JSON object, as text or as the path of a file, that maps
 * "owner/name" to {dir, commit?, license?}: those repositories are read from the directory instead of GitHub.
 */
export function openSource(id, entry, { selfCommit } = {}) {
  const local = (() => {
    const value = process.env.RNL_GALLERY_LOCAL;
    if (!value) return {};
    return JSON.parse(existsSync(value) ? readFileSync(value, "utf8") : value);
  })();
  const self = !entry.source;
  const repo = self ? SELF_REPO : entry.source.repo;
  const commit = self ? (selfCommit ?? process.env.GITHUB_SHA ?? "0".repeat(40)) : entry.source.commit;
  const prefix = self ? `examples/${id}/` : "";
  const l = local[repo];
  if (l) return new LocalSource({ repo, commit: self ? commit : (l.commit ?? commit), prefix, dir: l.dir, licenseId: l.license });
  return new GitHubSource({ repo, commit, prefix });
}
