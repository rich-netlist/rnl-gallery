// Downloads the fonts the thumbnails are drawn with into tools/fonts/ and checks their SHA-256, the same pinned
// files and hashes as scripts/fonts.py in https://github.com/rich-netlist/rnl (Noto Sans SC, SIL OFL 1.1).
import { mkdirSync, existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { sha256, fetchRetry } from "./lib/util.mjs";

const TAG = "Sans2.004";
export const FACES = [
  ["NotoSansSC-Regular.otf", "faa6c9df652116dde789d351359f3d7e5d2285a2b2a1f04a2d7244df706d5ea9"],
  ["NotoSansSC-Bold.otf", "c6cb5a93abaa9edc8ee7463b7ebb7f42d618d40e6ed2f7a5371c97b0b64767c0"],
];
export const FONT_DIR = join(dirname(fileURLToPath(import.meta.url)), "fonts");

export async function ensureFonts() {
  mkdirSync(FONT_DIR, { recursive: true });
  for (const [file, want] of FACES) {
    const path = join(FONT_DIR, file);
    if (existsSync(path) && sha256(readFileSync(path)) === want) continue;
    const response = await fetchRetry(`https://github.com/notofonts/noto-cjk/raw/${TAG}/Sans/SubsetOTF/SC/${file}`, { timeout: 120000 });
    if (!response.ok) throw new Error(`${file}: HTTP ${response.status}`);
    const bytes = Buffer.from(await response.arrayBuffer());
    if (sha256(bytes) !== want) throw new Error(`${file}: SHA-256 ${sha256(bytes)}, not the pinned ${want}`);
    writeFileSync(path, bytes);
  }
  return FACES.map(([file]) => join(FONT_DIR, file));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) console.log((await ensureFonts()).join("\n"));
