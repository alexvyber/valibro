import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {filterNativeDateRows} from '../../shared/native_scope.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/primitives/generate_conversion_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from "node:fs";
import cp from "node:child_process";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const inputs = [
    "",
    " ",
    "true",
    "TRUE",
    "false",
    "yes",
    "off",
    "1",
    "0",
    "-0",
    "+1",
    "1.5",
    "1e3",
    "1e999",
    "-1e-999",
    "Infinity",
    "NaN",
    "0xFF",
    "0b101",
    "0o17",
    "-0x1",
    "+001",
    "007",
    "0xg",
    "1_000",
    "é",
    "\ufeff1\u00a0",
    "\u0000",
    '"a"',
    "null",
    "[1,2]",
    '{"a":1}',
    "2010-01-01T00:00:00Z",
    "2024-02-30T00:00:00Z",
    "2024-01-32T00:00:00Z",
    "+275760-09-13T00:00:00Z",
];
const configs = [
    null,
    {truthy : [ "YES", "İ", "Σ", "ß" ], falsy : [ "NO", "ẞ", "σ" ]},
    {truthy : [ "same", "true" ], falsy : [ "same", "false" ]},
    {truthy : [], falsy : []},
];
const rows = [];
for (const action of ["toNumber", "toBigint", "toBoolean", "parseBoolean", "toDate"])
    for (const mode of ["default", "factory", "config"])
        for (const booleanConfig of action === "parseBoolean" ? configs : [ null ]) {
            const args =
        action === "parseBoolean"
          ? [booleanConfig ?? undefined, mode === "factory" ? "Factory message" : undefined]
          : [mode === "factory" ? "Factory message" : undefined];
            const s = v.pipe(v.string(), v[action](...args));
            const values =
                action === "parseBoolean"
                    ? [...inputs, "İ", "i\u0307", "Σ", "σ", "ς", "ß", "ẞ", "YES", "same" ]
                    : inputs;
            for (const input of values) {
                // Other date inputs can depend on the host timezone and are in the
                // explicit-timezone date corpus.
                if (action === "toDate" && !input.includes("T") &&
                    !["NaN", "0xg", "1_000", "é", "\u0000"].includes(input))
                    continue;
                const r = v.safeParse(s, input,
                                      mode === "config" ? {message : "Config message"} : {}),
                      issue = r.issues?.[0];
                const output =
                    r.success ? action === "toDate" ? String(r.output.getTime()) : String(r.output)
                              : "";
                rows.push({
                    action,
                    input,
                    mode,
                    boolean_config : booleanConfig,
                    success : r.success,
                    output,
                    expected : issue?.expected ?? "",
                    received : issue?.received ?? "",
                    message : issue?.message ?? "",
                    code : issue?.type ?? "",
                });
            }
        }
const target = "tests/fixtures/primitives/conversion_differential.json";
rows.splice(0,rows.length,...filterNativeDateRows('conversion',rows));
writeReferenceFixture('conversion', rows);
fs.writeFileSync(
    target.replace(".json", ".sources.json"),
    JSON.stringify(
        {
            node : process.version,
            revision : cp.execFileSync("git", [ "-C", process.argv[2], "rev-parse", "HEAD" ], {
                             encoding : "utf8"
                         }).trim(),
            outcomes : rows.length,
            scope :
                "Typed string conversions, Unicode/custom boolean configurations and full failure fields under factory/config messages. Timezone-dependent legacy dates are covered separately.",
        },
        null,
        2,
        ) +
        "\n",
);
console.log(rows.length + " conversion outcomes");
