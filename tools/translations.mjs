#!/usr/bin/env node
// Warns, on a pull request, of the translations of an entry's title and description whose English the change
// edits while it leaves them as they were: a GitHub annotation for each, never a failure.
// usage: node tools/translations.mjs <base-ref>
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { staleTranslations } from "./lib/translations.mjs";

const git = (...args) => execFileSync("git", args, { encoding: "utf8" });
const base = git("merge-base", process.argv[2], "HEAD").trim();
const names = git("diff", "--name-only", "--diff-filter=M", base, "HEAD").split("\n")
  .filter((name) => /^entries\/[^/]+\.json$/.test(name));
let count = 0;
for (const name of names) {
  let before, after;
  try {
    before = JSON.parse(git("show", `${base}:${name}`));
    after = JSON.parse(readFileSync(name, "utf8"));
  } catch {
    continue; // the check of the entries reports a file that is not JSON
  }
  for (const { field, lang } of staleTranslations(before, after)) {
    count++;
    console.log(`::warning file=${name}::The English of the ${field} changed and its "${lang}" did not. ` +
      `Update the translation, or remove it so that the English is shown; neither is required to merge.`);
  }
}
console.log(count ? `${count} translation${count === 1 ? "" : "s"} may be behind the English` : "no translation behind the English");
