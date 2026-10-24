// node --test tools/test.mjs
import test from "node:test";
import assert from "node:assert/strict";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { startCore } from "@rich-netlist/runtime";
import { validateEntry } from "./lib/entry.mjs";
import { checkLicense } from "./lib/license.mjs";
import { LocalSource } from "./lib/sources.mjs";
import { resolveEntry } from "./lib/resolve.mjs";
import { thumbnail } from "./lib/thumb.mjs";
import { ensureFonts } from "./fonts.mjs";
import { EntryError, sha256 } from "./lib/util.mjs";

const mini = join(dirname(fileURLToPath(import.meta.url)), "test", "fixtures", "mini");
const base = { title: { en: "T" }, description: { en: "D" }, author: "A", entry: "top.sp" };
const source = (license = "CC0-1.0") => new LocalSource({ repo: "example/mini", commit: "a".repeat(40), dir: mini, licenseId: license });

test("entries: the fields and their limits", () => {
  validateEntry("ota", { ...base });
  validateEntry("ota", { ...base, source: { repo: "owner/name", commit: "0123456789abcdef0123456789abcdef01234567" }, paths: ["lib", "cells/"], add: ["pdk/"], packages: [{ name: "eda-symbol", version: "0.3" }, { path: "p.rnl" }], level: "(top)" });
  const bad = (entry, id = "ota") => assert.throws(() => validateEntry(id, entry), EntryError);
  bad({ ...base, title: undefined });
  bad({ ...base, title: { zh: "只有中文" } });
  bad({ ...base, extra: 1 });
  bad({ ...base, source: { repo: "owner/name", commit: "main" } }, "ota");
  bad({ ...base, source: { repo: "not a repo", commit: "a".repeat(40) } });
  bad({ ...base, entry: "../x.sp" });
  bad({ ...base, entry: "/etc/x.sp" });
  bad({ ...base, entry: "top.txt" });
  bad({ ...base, paths: ["a/../b"] });
  bad({ ...base, packages: [{ name: "x" }] });
  bad({ ...base, packages: [{ url: "https://example.com/p.rnl" }] });
  bad({ ...base }, "Bad_Id");
});

test("licences: a recognised, permitting licence is required", () => {
  assert.equal(checkLicense("MIT"), null);
  assert.equal(checkLicense("GPL-3.0-only"), null);
  assert.equal(checkLicense("CC0-1.0"), null);
  for (const spdx of [null, "NOASSERTION", "CC-BY-NC-4.0", "CC-BY-ND-4.0", "LicenseRef-custom"]) assert.ok(checkLicense(spdx), String(spdx));
});

test("resolving: files, pool, hashes, and a thumbnail", async (t) => {
  const core = startCore();
  t.after(() => core.terminate());
  const { manifest, document, level, warnings } = await resolveEntry("mini", { ...base, paths: ["lib"] }, source(), { core });
  assert.equal(manifest.format, 1);
  assert.equal(manifest.license, "CC0-1.0");
  assert.equal(manifest.base, `https://raw.githubusercontent.com/example/mini/${"a".repeat(40)}/`);
  // the bare include is found through the pool; the unused file is left out
  assert.deepEqual(manifest.files.map((f) => f.path), ["top.sp", "lib/models.inc"]);
  assert.deepEqual(manifest.pool, ["lib/models.inc"]);
  assert.equal(manifest.files[1].sha256, sha256((await source().read("lib/models.inc"))));
  assert.equal(document.diagnostics.filter((d) => d.severity === "error").length, 0);
  assert.deepEqual(warnings, []);
  assert.ok(level.svg.length > 1000);
  const fonts = await ensureFonts();
  const thumb = thumbnail(level.svg, fonts);
  assert.equal(thumb.width, 640);
  assert.equal(thumb.png.subarray(1, 4).toString(), "PNG");
});

test("resolving: refusals", async (t) => {
  const core = startCore();
  t.after(() => core.terminate());
  await assert.rejects(resolveEntry("mini", { ...base, paths: ["lib"] }, source(null), { core }), /no licence/);
  await assert.rejects(resolveEntry("mini", { ...base, paths: ["lib"] }, source("CC-BY-NC-4.0"), { core }), /not on the list/);
  await assert.rejects(resolveEntry("mini", { ...base, entry: "nope.sp" }, source(), { core }), /is not in example\/mini/);
  await assert.rejects(resolveEntry("mini", { ...base, paths: ["lib"], level: "nothing" }, source(), { core }), /level "nothing" is not one of/);
  await assert.rejects(resolveEntry("mini", { ...base, add: ["missing.inc"] }, source(), { core }), /add: "missing.inc"/);
  // without `paths`, models.inc is looked for beside top.sp only, so the include cannot be found
  await assert.rejects(resolveEntry("mini", { ...base }, source(), { core }), EntryError);
});
