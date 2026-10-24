// Licences a repository may have for an entry to be accepted. A thumbnail of the design is published
// by this gallery, so the licence has to allow showing it: no licence (all rights reserved), non-commercial,
// no-derivatives and custom licences are refused. See "Licences" in README.md.
export const ALLOWED = [
  "CC0-1.0", "CC-BY-4.0", "CC-BY-SA-4.0", "MIT", "MIT-0", "BSD-2-Clause", "BSD-3-Clause", "ISC", "Apache-2.0",
  "Unlicense", "MPL-2.0", "0BSD", "Zlib",
  "GPL-2.0", "GPL-3.0", "LGPL-2.1", "LGPL-3.0", "AGPL-3.0",
];

/** Normalise the SPDX ids GitHub reports, such as "GPL-3.0" and "GPL-3.0-only". */
export const normalise = (spdx) => (spdx || "").replace(/-(only|or-later)$/, "");

// What an example of this repository must show in the LICENSE file of its directory for the licence its entry
// declares: a phrase of the standard text. Other licences are not accepted for the examples kept here.
export const MARKERS = {
  "CC0-1.0": /CC0 1\.0 Universal/,
  "CC-BY-4.0": /Attribution 4\.0 International/,
  "CC-BY-SA-4.0": /Attribution-ShareAlike 4\.0 International/,
  "MIT": /Permission is hereby granted, free of charge/,
  "Apache-2.0": /Apache License\s+Version 2\.0/,
  "Unlicense": /free and unencumbered software released into the public domain/,
};

export function checkDirectoryLicense(spdx, text, where) {
  if (!MARKERS[spdx]) return `${where}: the licence ${spdx} is not one an example of this repository may have (${Object.keys(MARKERS).join(", ")})`;
  if (!MARKERS[spdx].test(text)) return `${where} is not the text of ${spdx}`;
  return null;
}

export function checkLicense(spdx) {
  if (!spdx || spdx === "NOASSERTION") return "the repository has no licence GitHub can recognise (add a LICENSE file, or ask a maintainer for an exception)";
  const id = normalise(spdx);
  if (ALLOWED.includes(spdx) || ALLOWED.includes(id)) return null;
  return `the licence ${spdx} is not on the list of accepted licences (README.md, "Licences")`;
}
