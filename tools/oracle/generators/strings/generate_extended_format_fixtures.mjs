import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/strings/generate_extended_format_fixtures.mjs VALIBOT_CHECKOUT
import fs from "node:fs";
import cp from "node:child_process";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const originals = JSON.parse(fs.readFileSync("tests/fixtures/strings/string_formats.json"));
const schemas = new Map();
const rows = [];
const seen = new Set();
for (const original of originals) {
    const action = original.action;
    const method = action.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
    if (!schemas.has(action))
        schemas.set(action, v.pipe(v.string(), v[method]()));
    const s = original.input;
    for (const input of [s + "\n",
                         "\n" + s,
                         s + "\r",
                         s + "\u2028",
                         s + "\0",
                         "\0" + s,
                         s.replaceAll("k", "K").replaceAll("s", "ſ"),
                         s + "é",
                         s + "🙂",
    ]) {
        const key = JSON.stringify([ action, input ]);
        if (seen.has(key))
            continue;
        seen.add(key);
        const result = v.safeParse(schemas.get(action), input);
        rows.push({
            action,
            input,
            valid : result.success,
            message : result.issues?.[0]?.message ?? "",
            received : result.issues?.[0]?.received ?? "",
        });
    }
}
fs.writeFileSync("tests/fixtures/engines/formats_extended.json", JSON.stringify(rows) + "\n");
console.log(rows.length + " extended format outcomes");

fs.writeFileSync(
    "tests/fixtures/engines/formats_extended.sources.json",
    JSON.stringify(
        {
            reference : {
                node : process.version,
                versions : process.versions,
                valibot :
                    cp.execFileSync("git",
                                    [ "-C", path.resolve(process.argv[2]), "rev-parse", "HEAD" ], {
                                        encoding : "utf8",
                                    })
                        .trim(),
            },
            outcomes : rows.length,
            scope :
                "Original format inputs mutated with controls, case folding and Unicode suffixes.",
        },
        null,
        2,
        ) +
        "\n",
);
