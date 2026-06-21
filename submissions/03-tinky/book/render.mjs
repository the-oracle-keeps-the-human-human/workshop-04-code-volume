// render.mjs — BOOK.md -> BOOK.pdf + page-*.png
// Thai-aware book renderer. Uses marked (md->html) + puppeteer (html->pdf/png).
// Run:  cd book && npm i marked puppeteer && node render.mjs
//   or: npx --yes -p marked -p puppeteer node render.mjs
import { readFileSync, writeFileSync } from "node:fs";
import { marked } from "marked";
import puppeteer from "puppeteer";

const md = readFileSync(new URL("./BOOK.md", import.meta.url), "utf8");
const body = marked.parse(md);

// Thai web font via Google Fonts (Sarabun) so glyphs render in headless Chrome.
const html = `<!doctype html><html lang="th"><head><meta charset="utf-8">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Sarabun:wght@400;600;700&family=JetBrains+Mono&display=swap" rel="stylesheet">
<style>
  * { box-sizing: border-box; }
  body { font-family: 'Sarabun', sans-serif; line-height: 1.7; color: #1a1a2e;
         max-width: 760px; margin: 0 auto; padding: 48px 56px; font-size: 15px; }
  h1 { color: #6a0dad; border-bottom: 3px solid #ffd700; padding-bottom: .3em; }
  h2 { color: #5a189a; margin-top: 1.8em; }
  h3 { color: #7b2cbf; }
  blockquote { border-left: 4px solid #ffd700; margin: 1em 0; padding: .4em 1em;
               background: #fff9e6; color: #555; font-style: italic; }
  code, pre { font-family: 'JetBrains Mono', monospace; }
  pre { background: #1a1a2e; color: #e0d7ff; padding: 14px 18px; border-radius: 8px;
        overflow-x: auto; font-size: 12.5px; line-height: 1.5; }
  code:not(pre code){ background:#f0e6ff; color:#6a0dad; padding:1px 5px; border-radius:4px; }
  table { border-collapse: collapse; width: 100%; margin: 1em 0; font-size: 13px; }
  th,td { border: 1px solid #d4c5f0; padding: 6px 10px; text-align: left; }
  th { background: #f0e6ff; color: #5a189a; }
  hr { border: none; border-top: 2px dashed #ffd700; margin: 2em 0; }
  strong { color: #6a0dad; }
</style></head><body>${body}</body></html>`;

writeFileSync(new URL("./BOOK.html", import.meta.url), html);

const browser = await puppeteer.launch({
  headless: "new",
  args: ["--no-sandbox", "--disable-setuid-sandbox"],
});
const page = await browser.newPage();
await page.setContent(html, { waitUntil: "networkidle0" });

await page.pdf({
  path: new URL("./BOOK.pdf", import.meta.url).pathname,
  format: "A4",
  printBackground: true,
  margin: { top: "16mm", bottom: "16mm", left: "14mm", right: "14mm" },
});
console.log("✓ BOOK.pdf");

// page PNGs: paginate by A4 height at 96dpi (~1123px) on the full-page screenshot.
await page.setViewport({ width: 820, height: 1123, deviceScaleFactor: 2 });
const fullHeight = await page.evaluate(() => document.body.scrollHeight);
const pageH = 1123;
const n = Math.ceil(fullHeight / pageH);
for (let i = 0; i < n; i++) {
  await page.screenshot({
    path: new URL(`./page-${String(i + 1).padStart(2, "0")}.png`, import.meta.url).pathname,
    clip: { x: 0, y: i * pageH, width: 820, height: Math.min(pageH, fullHeight - i * pageH) },
  });
}
console.log(`✓ ${n} page PNGs`);
await browser.close();
