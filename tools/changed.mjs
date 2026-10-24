#!/usr/bin/env node
// Prints which entries a change touches, for the check on a pull request: a comma-separated list of ids,
// or "all" when the tools, the schema or a workflow changed, or "none".
// usage: node tools/changed.mjs <base-ref>
import { execFileSync } from "node:child_process";

const base = process.argv[2];
const names = execFileSync("git", ["diff", "--name-only", `${base}...HEAD`], { encoding: "utf8" }).split("\n").filter(Boolean);
const ids = new Set();
let all = false;
for (const name of names) {
  let m;
  if ((m = /^entries\/([^/]+)\.json$/.exec(name))) ids.add(m[1]);
  else if ((m = /^examples\/([^/]+)\//.exec(name))) ids.add(m[1]);
  else if (/^(tools|schema|\.github)\//.test(name)) all = true;
}
console.log(all ? "all" : ids.size ? [...ids].sort().join(",") : "none");
