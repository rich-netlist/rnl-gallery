# RNL gallery

Examples of circuits drawn with [RNL](https://github.com/rich-netlist/rnl) (Rich Netlist), shown on the project's site: <https://rich-netlist.github.io/rnl/gallery.html>.

The gallery is a **list**. Each entry points to a design in a public GitHub repository, at one commit; nothing of the design is copied here. Opening an entry opens that commit's files in the [web viewer](https://rich-netlist.github.io/rnl/viewer/). Examples of our own are kept in this repository, in `examples/`, and are entries like any other.

## Add a design

Open a pull request that adds one file, `entries/<id>.json` (see [CONTRIBUTING.md](CONTRIBUTING.md)). The designer does not have to do anything: anybody may suggest a design from a public repository with a licence that allows it (below).

```json
{
  "title": {"en": "Phase-locked loop", "zh": "锁相环"},
  "description": {"en": "A hierarchical PLL …", "zh": "…"},
  "author": "Name",
  "source": {"repo": "owner/name", "commit": "<the full 40-digit commit id>"},
  "entry": "top.scs",
  "paths": ["cells"],
  "add": ["models/"],
  "packages": [{"name": "eda-symbol", "version": "0.3"}, {"path": "semantics.rnl"}],
  "tags": ["pll", "mixed-signal"],
  "cover": {"cell": "lc_vco", "view": "schematic"}
}
```

| Field | |
| --- | --- |
| `title`, `description`, `author` | What the gallery shows. `title` and `description` have an `en` text and may have others (`zh`). English is RNL's only core language: an entry may have its English alone, and a translation follows it. When you change the English, change its translations too or remove them, so that the English is shown; the check of the pull request warns of a translation left as it was, and does not fail. `author` is a name, or a list of `{"name": "…", "url": "…"}` (the link is optional and has to be https): the card shows the names in order, and a name with a link can be clicked. |
| `license` | Optional for a design in another repository (its repository's licence is read otherwise), required for an example kept here. An SPDX id from the list below. See [Licences](#licences). |
| `source` | The repository (`owner/name`, on GitHub) and the **full commit id**: never a branch or a tag, so that what is shown is what was reviewed. Leave it out for an example kept in `examples/<id>/` of this repository. |
| `entry` | The netlist (SPICE, `.sp`/`.spi`/`.cir`/`.net`, or Spectre, `.scs`) the viewer opens, relative to the repository. |
| `paths` | Directories searched for include files written with a bare name, in order (the directory of the entry by default). |
| `add` | Files or directories to take in besides what the netlist includes. A directory is taken with what is below it. Rarely needed: the files the netlist includes are found by reading it. |
| `packages` | Packages to load: `{"name", "version"}` from the [public catalog](https://rich-netlist.github.io/rnl-packages/catalog.json), `{"path"}` a file of the repository, or `{"url"}` a raw.githubusercontent.com address. The standard packages need no entry. |
| `tags` | Up to 8 tags to find the design by, written as they are to be shown (`"180nm CMOS"`, `"PLL"`, `"AI-gen"`): letters, digits, single spaces and `- . + /`, at most 32 characters. The gallery shows them as written and filters by them without regard to case, a space counting as a hyphen (`180nm-cmos` in an address), so `PLL` and `pll` are one tag. They are not translated. |
| `formats` | The files that have to be told how to be read: `{"models/n.lib": "spectre"}`, a file of the design and `"spice"` or `"spectre"`. Only the files the core would guess wrong (it goes by the suffix and the first lines); leave it out otherwise. The checks and the viewer read the files with these formats. |
| `cover` | What the thumbnail shows, and what the viewer opens first: `{"cell": "lc_vco", "view": "schematic"}`, or `"view": "symbol"` for the symbol of that cell (the cell's own block symbol, which its netlist has to define). `cell` is a subcircuit name, or `"(top)"` for the netlist's own level; `view` is `"schematic"` unless it says otherwise; without `cell`, the first level that draws something. Pick what shows the design best. |
| `level` | The older way to say `{"cover": {"cell": …}}` (a schematic); not together with `cover`. |

### Tags

Tags are shown as they are written, in every language, so write them in the form to show: the capitals of `PLL`, `ADC`, `CMOS`, `AI-gen`. Suggested, so that the same thing has the same tag: `Amplifier`, `Op-amp`, `OTA`, `Comparator`, `Bandgap`, `Reference`, `Bias`, `LDO`, `Power`, `Oscillator`, `VCO`, `PLL`, `ADC`, `SAR ADC`, `DAC`, `Filter`, `Switched-capacitor`, `Mixed-signal`, `Digital`, `RF`, `LNA`, `Mixer`, `Hierarchical`, `Transistor-level`, `Virtuoso export`, and the process, such as `28nm CMOS`. Others are allowed; the checks look only at the form.

## What the checks do

On a pull request, and when it is merged, `tools/build.mjs` takes each entry and:

1. finds the licence of the design and refuses the entry unless it is one of the accepted licences (below): for an example kept here, the entry's `license`, which has to be the licence of the `LICENSE` file in its directory; for a design in another repository, the repository's licence, or the entry's `license` when it declares one;
2. lists the files of the commit and fetches the ones the netlist needs: the entry, what it includes, the packages, what `paths` and `add` name;
3. runs the same core as the viewer (`@rich-netlist/runtime`, as WebAssembly) on exactly these files: **errors fail the check**, warnings are shown;
4. draws the thumbnail (a PNG, 640 pixels wide): the schematic of the chosen cell, or its symbol;
5. writes a *manifest* for the entry, with every file's address and SHA-256, the order in which bare includes are searched, the packages and the level. The viewer opens an entry from its manifest, and checks every file against it.

The merged result is published to this repository's GitHub Pages: `index.json`, `manifests/<id>.json` and `thumbs/…png`, at <https://rich-netlist.github.io/rnl-gallery/>. The site reads `index.json` and the thumbnails there, so that a new entry shows up a few minutes after it is merged, with no change to the site. Nothing but GitHub's static files is used: no server, and no GitHub API from the browser.

Limits: at most 300 files, 2 MB each and 20 MB together, per entry. Only public GitHub repositories are supported: other hosts do not send the headers a browser needs to read their files from another site.

## Licences

**Each design has its own licence**, and the gallery shows it on the card with the author's name.

- **An example kept here** (`examples/<id>/`) has its own `LICENSE` file, with the text of its licence, and its entry says which in `license` (an SPDX id). The checks compare the two. Only some licences are accepted for these (CC0-1.0, CC-BY-4.0, CC-BY-SA-4.0, MIT, Apache-2.0, Unlicense), so that the text can be recognised.
- **A design in another repository** is licensed as its repository is: the checks read the repository's licence. When the entry has a `license` field, that is what the card shows, and a reviewer checks it against the repository (for a design with a licence of its own in a repository with another one, or whose licence GitHub cannot recognise).

The gallery makes a picture of each design itself, so it takes only designs whose licence allows showing one: CC0-1.0, CC-BY-4.0, CC-BY-SA-4.0, MIT, MIT-0, BSD-2-Clause, BSD-3-Clause, ISC, Apache-2.0, Unlicense, MPL-2.0, 0BSD, Zlib, and the GPL, LGPL and AGPL families. A design with **no licence** (all rights are reserved), under a non-commercial or no-derivatives licence, or under a licence of its own, is refused by the checks. The list is in `tools/lib/license.mjs`. The files of a design stay under its licence; the viewer reads them from where they are.

**Taking an entry down.** The owner of a design, or anybody else with a reason, can ask in an issue to have its entry removed. It is deleted, and its thumbnail and manifest go with the next publication.

Material under an NDA, or foundry data that may not be published, does not belong here, in this repository or in any repository an entry points to.

### The examples kept here

| Example | Licence | If you reuse it |
| --- | --- | --- |
| `pll` | CC0-1.0 | Nothing is required. It was designed by GPT-6-Astra, and its schematic and comments were generated by Gemini-4-Argon (language models). |
| `risca` | CC-BY-4.0 | Credit the authors (many-question; the comments on its drawings were generated by Gemini-4-Argon), link to this repository and to the licence, and say if you changed it. The gallery credits them on the card of the thumbnail. |

## The files of this repository

| Path | |
| --- | --- |
| `entries/<id>.json` | The list: one file per entry. |
| `examples/<id>/` | The files of the examples kept here. They are entries without a `source`, and their paths are relative to this directory. |
| `schema/entry.schema.json` | The entry's JSON Schema, for editors. `tools/lib/entry.mjs` is what the checks run. |
| `tools/` | The checks and the build (Node, MIT licence, see below). |
| `.github/workflows/` | `check.yml` on pull requests, `pages.yml` on merges and every night. |

### Build it here

Node 22 or later. The core and the rasteriser come from npm, the fonts are downloaded and checked against pinned SHA-256 sums.

```bash
npm ci --prefix tools
node --test tools/test.mjs
GITHUB_TOKEN=… node tools/build.mjs --out dist     # the token is optional; it only lifts the API's rate limit
```

`--only id,id` builds some entries. `RNL_GALLERY_LOCAL` is a JSON object, as text or as the path of a file, from `"owner/name"` to `{"dir": "…", "license": "CC0-1.0"}`: those repositories are read from the directory instead of GitHub, to try an entry before it is pushed.

## Licence of this repository

It follows [REUSE](https://reuse.software): [`REUSE.toml`](REUSE.toml) says the licence of each path, and the texts are in [`LICENSES/`](LICENSES). The code in `tools/` and the workflows are under the MIT licence; the entries, the schema and the documentation are under CC0-1.0; each example is under the licence of its own directory, as above.
