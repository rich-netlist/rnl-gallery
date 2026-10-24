import { Resvg } from "@resvg/resvg-js";
import { sha256 } from "./util.mjs";

export const THUMB_WIDTH = 640;

/** A level's SVG as a PNG of a fixed width on white, drawn with the pinned fonts only. */
export function thumbnail(svg, fontFiles) {
  const image = new Resvg(svg, {
    fitTo: { mode: "width", value: THUMB_WIDTH },
    background: "#ffffff",
    font: { loadSystemFonts: false, fontFiles, defaultFontFamily: "Noto Sans SC" },
  }).render();
  const png = image.asPng();
  return { png, width: image.width, height: image.height, hash: sha256(png).slice(0, 8) };
}
