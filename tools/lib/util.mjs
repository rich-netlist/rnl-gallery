import { createHash } from "node:crypto";

export const sha256 = (bytes) => createHash("sha256").update(bytes).digest("hex");

export const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/** fetch with a time limit per attempt and a few retries on network errors and 5xx/429. */
export async function fetchRetry(url, { headers = {}, tries = 4, timeout = 30000 } = {}) {
  let last;
  for (let attempt = 1; attempt <= tries; attempt++) {
    try {
      const response = await fetch(url, { headers, signal: AbortSignal.timeout(timeout) });
      if (response.status < 500 && response.status !== 429) return response;
      last = new Error(`${url}: HTTP ${response.status}`);
    } catch (error) {
      last = new Error(`${url}: ${error.message}`);
    }
    if (attempt < tries) await sleep(1000 * attempt);
  }
  throw last;
}

/** Run `fn` over `items` with at most `limit` at once, keeping the order of the results. */
export async function mapLimit(items, limit, fn) {
  const results = new Array(items.length);
  let next = 0;
  const worker = async () => {
    for (;;) {
      const i = next++;
      if (i >= items.length) return;
      results[i] = await fn(items[i], i);
    }
  };
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return results;
}

/** A user-facing problem with an entry: reported as is, without a stack. */
export class EntryError extends Error {}

export const posixJoin = (...parts) => parts.join("/").replace(/\/+/g, "/");
