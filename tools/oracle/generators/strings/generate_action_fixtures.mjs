import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/strings/generate_action_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from "node:fs";
import cp from "node:child_process";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const rows = [];
const units = (s) => Array.from({length : s.length}, (_, i) => s.charCodeAt(i));
function add(domain, action, requirement, inputs) {
    for (const mode of ["default", "factory", "config"]) {
        const message = mode === "factory" ? "Factory message" : undefined;
        const args = action.endsWith("Words") || action === "words" ? [ "en", requirement, message ]
                     : [ "empty", "nonEmpty", "finite", "integer", "safeInteger" ].includes(action)
                         ? [ message ]
                         : [ requirement, message ];
        const check = v[action](...args);
        const schema = v.pipe(v.unknown(), check);
        for (const input of inputs) {
            // Dictionary-tailored Intl.Segmenter counts are outside native UAX #29 scope.
            // These inputs remain covered for every other string action and by native word tests.
            if ((action.endsWith('Words') || action === 'words') &&
                ['東京に行きます', 'ภาษาไทย'].includes(input)) continue;
            const result = v.safeParse(schema, input, {
                ...(mode === "config" ? {message : "Config message"} : {}),
            });
            const issue = result.issues?.[0];
            rows.push({
                domain,
                action,
                requirement : encode(requirement),
                input : encode(input),
                mode,
                success : result.success,
                expected : units(issue?.expected ?? ""),
                received : units(issue?.received ?? ""),
                message : units(issue?.message ?? ""),
                code : issue?.type ?? "",
            });
        }
    }
}
const encode = (x) => typeof x === "number" ? Number.isNaN(x)    ? "NaN"
                                              : x === Infinity   ? "Infinity"
                                              : x === -Infinity  ? "-Infinity"
                                              : Object.is(x, -0) ? "-0"
                                                                 : x
                      : Array.isArray(x)    ? x.map(encode)
                                            : (x ?? null);
const strings = [
    "",
    "a",
    "b",
    " ab ",
    "abcdef",
    "🙂",
    "a🙂b",
    "é",
    "e\u0301",
    "👩‍💻",
    "東京に行きます",
    "ภาษาไทย",
    "hello world",
    "a\n",
    "\u0000",
    "𐀀",
    "\uffff",
];
for (const family of ["Length", "Bytes", "CodePoints", "Graphemes", "Words"])
    for (const prefix of ["", "min", "max", "not"]) {
        const action = prefix ? prefix + family : family[0].toLowerCase() + family.slice(1);
        for (const n of [-1, 0, 1, 2, 3, 5])
            add("string", action, n, strings);
    }
for (const action of ["empty", "nonEmpty"])
    add("string", action, null, strings);
for (const action of ["startsWith",
                      "endsWith",
                      "includes",
                      "excludes",
                      "value",
                      "notValue",
                      "minValue",
                      "maxValue",
                      "gtValue",
                      "ltValue",
])
    for (const r of ["", "a", "🙂", "a🙂", "\uffff"])
        add("string", action, r, strings);
for (const action of ["values", "notValues"])
    for (const r of [[], [ "a" ], [ "a", "b", "a" ], [ "🙂", "𐀀" ]])
        add("string", action, r, strings);
const numbers = [
    NaN,
    Infinity,
    -Infinity,
    -0,
    0,
    0.1,
    0.3,
    -1,
    1,
    1.5,
    2,
    9007199254740992,
    1e100,
    Number.MIN_VALUE,
];
for (const action of ["finite", "integer", "safeInteger"])
    add("number", action, null, numbers);
for (const action of ["minValue",
                      "maxValue",
                      "gtValue",
                      "ltValue",
                      "value",
                      "notValue",
                      "multipleOf",
])
    for (const r of [NaN, Infinity, -Infinity, -0, 0, 1, -1, 0.1, 2])
        add("number", action, r, numbers);
for (const action of ["values", "notValues"])
    for (const r of [[], [ NaN ], [ 0, -0, 1 ], [ 1, 1, 2 ], [ Infinity, -Infinity ]])
        add("number", action, r, numbers);
for (const action of ["length", "minLength", "maxLength", "notLength"])
    for (const r of [-1, 0, 1, 2, 5])
        add("array", action, r, [ [], [ 1 ], [ 1, 2 ], [ 1, 2, 3 ] ]);
for (const action of ["empty", "nonEmpty"])
    add("array", action, null, [ [], [ 1 ], [ 1, 2 ] ]);
const file = "tests/fixtures/strings/action_differential.json";
writeReferenceFixture('action', rows);
fs.writeFileSync(
    file.replace(".json", ".sources.json"),
    JSON.stringify(
        {
            node : process.version,
            upstream : cp.execFileSync("git", [ "-C", process.argv[2], "rev-parse", "HEAD" ], {
                             encoding : "utf8"
                         }).trim(),
            outcomes : rows.length,
            scope :
                "String, binary64 and array validations; word comparisons exclude Japanese/Thai dictionary tailoring (covered by native conformance tests). Success, code, expected, received and default/factory/config messages.",
        },
        null,
        2,
        ) +
        "\n",
);
console.log(rows.length + " action outcomes");
