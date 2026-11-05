import {loadValibot} from '../../shared/reference.mjs';
// Maintainer-only: node tools/oracle/generators/strings/generate_unicode_parity.mjs UPSTREAM_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const emoji = v.pipe(v.string(), v.emoji());
const rows = [];
for (let cp = 0; cp <= 0x10ffff; cp++) {
    if (cp >= 0xd800 && cp <= 0xdfff)
        continue;
    const input = String.fromCodePoint(cp), lower = input.toLowerCase(),
          upper = input.toUpperCase();
    const valid = v.safeParse(emoji, input).success;
    if (valid || lower !== input || upper !== input || cp % 97 === 0)
        rows.push({input, lower, upper, emoji : valid});
}
for (const input of ["",
                     "Straße",
                     "ΟΣ",
                     "ΟΣΑ",
                     "Α\u0301Σ",
                     "Σ",
                     "İSTANBUL",
                     "👩🏽‍💻",
                     "🇷🇺",
                     "🇺",
                     "🇷🇺🇬🇧",
                     "1",
                     "1️⃣",
                     "☀",
                     "☀️",
                     "👨‍👩‍👧‍👦",
                     "🏴\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}",
                     "🏽",
                     "a🙂",
                     "🙂🙂",
                     "❤️‍🔥",
]) {
    rows.push({
        input,
        lower : input.toLowerCase(),
        upper : input.toUpperCase(),
        emoji : v.safeParse(emoji, input).success,
    });
}
fs.writeFileSync(
    "tests/fixtures/strings/unicode_parity.json",
    JSON.stringify({unicode : process.versions.unicode, icu : process.versions.icu, rows}, null,
                   2) +
        "\n",
);
console.log(`${rows.length} casing/emoji cases; Unicode ${process.versions.unicode}`);

const formats = [];
for (const row of rows) {
    // Native casing classifies whole supplementary characters, not JS surrogates.
    if ([...row.input].some(ch => ch.codePointAt(0) > 0xffff)) continue;
    if (row.lower === row.input && row.upper === row.input)
        continue;
    for (const input of [`a${row.input}B`, `AB${row.input}c`]) {
        formats.push({
            input,
            camel : v.parse(v.pipe(v.string(), v.toCamelCase()), input),
            pascal : v.parse(v.pipe(v.string(), v.toPascalCase()), input),
            kebab : v.parse(v.pipe(v.string(), v.toKebabCase()), input),
            snake : v.parse(v.pipe(v.string(), v.toSnakeCase()), input),
        });
    }
}
fs.writeFileSync("tests/fixtures/strings/case_format_parity.json", JSON.stringify(formats, null, 2) + "\n");
console.log(`${formats.length} contextual case-format inputs`);
