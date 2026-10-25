// The translations of an entry that may have fallen behind their English. English is RNL's only core language
// (its decision 0015): a translation follows the English, and one left as it was when the English changed is
// reported, never refused.

/** The fields whose texts have translations: { en, and other languages }. */
export const TRANSLATED = ["title", "description"];

const norm = (text) => String(text ?? "").split(/\s+/).filter(Boolean).join(" ");

/** The translations, [{ field, lang }], whose English changed from `before` to `after` while they did not. */
export function staleTranslations(before, after) {
  const found = [];
  for (const field of TRANSLATED) {
    const old = before?.[field], now = after?.[field];
    if (!old || !now || typeof old !== "object" || typeof now !== "object" || norm(old.en) === norm(now.en)) continue;
    for (const lang of Object.keys(now)) {
      if (lang !== "en" && typeof old[lang] === "string" && norm(old[lang]) === norm(now[lang])) found.push({ field, lang });
    }
  }
  return found;
}
