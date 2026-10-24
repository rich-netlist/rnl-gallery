// node --test tools/test.mjs
import test from "node:test";
import assert from "node:assert/strict";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { startCore } from "@rich-netlist/runtime";
import { validateEntry, authorList } from "./lib/entry.mjs";
import { checkLicense } from "./lib/license.mjs";
import { LocalSource } from "./lib/sources.mjs";
import { resolveEntry, searchCandidates } from "./lib/resolve.mjs";
import { thumbnail } from "./lib/thumb.mjs";
import { ensureFonts } from "./fonts.mjs";
import { EntryError, sha256 } from "./lib/util.mjs";

const mini = join(dirname(fileURLToPath(import.meta.url)), "test", "fixtures", "mini");
const selfDir = join(dirname(fileURLToPath(import.meta.url)), "test", "fixtures", "self");
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
  bad({ ...base, license: "CC-BY-NC-4.0" });
  // the cover: a cell's schematic or symbol; `level` is the older way to name a schematic
  validateEntry("ota", { ...base, cover: { cell: "amp", view: "symbol" }, tags: ["adc", "sar-adc", "mixed-signal"] });
  validateEntry("ota", { ...base, cover: { view: "schematic" } });
  bad({ ...base, cover: { cell: "amp" }, level: "amp" });
  bad({ ...base, cover: { view: "symbol" } });
  bad({ ...base, cover: { cell: "(top)", view: "symbol" } });
  bad({ ...base, cover: { cell: "amp", view: "layout" } });
  bad({ ...base, cover: { cell: "amp", extra: 1 } });
  bad({ ...base, tags: ["Upper"] });
  // authors: a name, or a list of names with an optional https link
  validateEntry("ota", { ...base, author: [{ name: "Ada", url: "https://github.com/ada" }, { name: "Gemini" }] });
  bad({ ...base, author: [] });
  bad({ ...base, author: [{ url: "https://x.org" }] });
  bad({ ...base, author: [{ name: "Ada", url: "http://x.org" }] });
  bad({ ...base, author: [{ name: "Ada", url: "javascript:alert(1)" }] });
  bad({ ...base, author: [{ name: "Ada", mail: "a@b.c" }] });
  bad({ ...base, author: ["Ada"] });
  assert.deepEqual(authorList("Ada"), [{ name: "Ada" }]);
  assert.deepEqual(authorList([{ name: "A", url: "https://a.org" }, { name: "B" }]), [{ name: "A", url: "https://a.org" }, { name: "B" }]);
  validateEntry("ota", { ...base, formats: { "lib/models.inc": "spice" } });
  bad({ ...base, formats: ["top.sp"] });
  bad({ ...base, formats: { "../x.inc": "spice" } });
  bad({ ...base, formats: { "lib/models.inc": 1 } });
  bad({ ...base, tags: ["a", "a"] });
  bad({ ...base, tags: "adc" });
  bad({ ...base, tags: Array.from({ length: 9 }, (_, i) => `t${i}`) });
  validateEntry("ota", { ...base, license: "CC-BY-4.0" });
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

const own = (id) => new LocalSource({ repo: "rich-netlist/rnl-gallery", commit: "b".repeat(40), prefix: `examples/${id}/`, dir: selfDir, self: true });

test("licences of the examples kept here and of entries that declare one", async (t) => {
  const core = startCore();
  t.after(() => core.terminate());
  const example = { ...base, paths: ["lib"], license: "CC0-1.0" };
  const { manifest } = await resolveEntry("mini", example, own("mini"), { core });
  assert.equal(manifest.license, "CC0-1.0");
  assert.equal(manifest.licenseBy, "directory");
  assert.equal(manifest.base, `https://raw.githubusercontent.com/rich-netlist/rnl-gallery/${"b".repeat(40)}/examples/mini/`);
  // the entry must declare it, and the directory must show the text of that licence
  await assert.rejects(resolveEntry("mini", { ...base, paths: ["lib"] }, own("mini"), { core }), /needs a "license"/);
  await assert.rejects(resolveEntry("mini", { ...example, license: "CC-BY-4.0" }, own("mini"), { core }), /is not the text of CC-BY-4.0/);
  await assert.rejects(resolveEntry("mini", { ...example, license: "MPL-2.0" }, own("mini"), { core }), /not one an example of this repository may have/);
  await assert.rejects(resolveEntry("nolicense", { ...base, license: "CC0-1.0" }, own("nolicense"), { core }), /LICENSE is missing/);
  // an entry for another repository: its own licence wins over what the repository says, and without one the repository's is used
  const declared = await resolveEntry("mini", { ...base, paths: ["lib"], license: "CC-BY-4.0" }, source(null), { core });
  assert.equal(declared.manifest.license, "CC-BY-4.0");
  assert.equal(declared.manifest.licenseBy, "entry");
  const inherited = await resolveEntry("mini", { ...base, paths: ["lib"] }, source("MIT"), { core });
  assert.deepEqual([inherited.manifest.license, inherited.manifest.licenseBy], ["MIT", "repo"]);
});

test("search directories give what rnl --path gives: files directly in them, packages one version directory down", () => {
  const list = ["top.sp", "lib/a.inc", "lib/b.txt", "lib/sub/c.inc", "pkgs/1.0/x.rnl", "pkgs/1.0/deep/y.rnl", "pkgs/z.rnl", "pkgs/1.0/n.sp"];
  assert.deepEqual(searchCandidates(list, "lib"), ["lib/a.inc"]);
  assert.deepEqual(searchCandidates(list, "pkgs"), ["pkgs/1.0/x.rnl", "pkgs/z.rnl"]);
  assert.deepEqual(searchCandidates(list, ""), ["top.sp", "pkgs/z.rnl"]);
});

test("the cover is a schematic or the symbol of a cell", async (t) => {
  const core = startCore();
  t.after(() => core.terminate());
  const sub = new LocalSource({ repo: "example/sub", commit: "c".repeat(40), dir: join(dirname(fileURLToPath(import.meta.url)), "test", "fixtures", "sub"), licenseId: "CC0-1.0" });
  const symbol = await resolveEntry("sub", { ...base, cover: { cell: "amp", view: "symbol" }, tags: ["amplifier"] }, sub, { core });
  assert.deepEqual(symbol.manifest.cover, { cell: "amp", view: "symbol" });
  assert.equal(symbol.manifest.level, "amp");
  assert.deepEqual(symbol.manifest.tags, ["amplifier"]);
  assert.match(symbol.svg, /^<svg /);
  assert.notEqual(symbol.svg, symbol.level.svg);
  const thumb = thumbnail(symbol.svg, await ensureFonts());
  assert.equal(thumb.width, 640);
  // `level` still names a schematic; the cover of the manifest says so
  const old = await resolveEntry("sub", { ...base, level: "amp" }, sub, { core });
  assert.deepEqual(old.manifest.cover, { cell: "amp", view: "schematic" });
  assert.deepEqual(old.manifest.tags, []);
  await assert.rejects(resolveEntry("sub", { ...base, cover: { cell: "nothing", view: "symbol" } }, sub, { core }), /level "nothing" is not one of/);
});

test("formats: told to the core, checked against its list, and carried in the manifest", async (t) => {
  const core = startCore();
  t.after(() => core.terminate());
  const entry = { ...base, paths: ["lib"], formats: { "top.sp": "spice", "lib/models.inc": "spice" } };
  const { manifest } = await resolveEntry("mini", entry, source(), { core });
  assert.deepEqual(manifest.formats, { "top.sp": "spice", "lib/models.inc": "spice" });
  assert.equal((await resolveEntry("mini", { ...base, paths: ["lib"] }, source(), { core })).manifest.formats, undefined);
  await assert.rejects(resolveEntry("mini", { ...entry, formats: { "top.sp": "cdl" } }, source(), { core }), /is not a format of the core \(spice, spectre\)/);
  await assert.rejects(resolveEntry("mini", { ...entry, formats: { "nowhere.inc": "spice" } }, source(), { core }), /is not a file of the design/);
  await assert.rejects(resolveEntry("mini", { ...entry, formats: { "lib/unused.inc": "spice" } }, source(), { core }), /is not one of the files the netlist reads/);
});
