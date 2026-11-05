import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/json/generate_json_config_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import cp from "node:child_process";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const inputs = [
    "null",
    "true",
    "0",
    "-0",
    "1.25",
    "1e2",
    '"hello"',
    '"é🙂"',
    "[]",
    "{}",
    "[1,2,3]",
    '{"a":1,"b":2,"nested":{"a":3,"drop":4}}',
    '{"10":1,"2":2,"a":3}',
    '{"a":1,"a":{"b":2}}',
    '{"a":{"b":2},"a":1}',
    '[null,true,"drop",{"a":-1,"drop":2}]',
    '"\\u0061"',
    "1.000",
    '  [ 1, "x", false ] ',
];
const parse = [];
const project = (x) =>
    JSON.parse(JSON.stringify(x, (_k, value) => (value === undefined ? null : value)));
for (const input of inputs)
    for (const mode of ["identity", "double", "delete", "rootUndefined", "source"]) {
        const calls = [];
        const reviver = function(key, value, context) {
            calls.push({key, source : context.source ?? null});
            if (mode === "double" && typeof value === "number")
                return value * 2;
            if (mode === "delete" && (key === "drop" || value === "drop"))
                return undefined;
            if (mode === "rootUndefined" && key === "")
                return undefined;
            if (mode === "source" && context.source !== undefined)
                return context.source;
            return value;
        };
        const r = v.safeParse(v.pipe(v.string(), v.parseJson({reviver})), input);
        parse.push({
            input,
            mode,
            success : r.success,
            undefined : r.output === undefined,
            output : project(r.output),
            calls,
        });
    }
const stringify = [];
const values = inputs.map((x) => JSON.parse(x));
values.push(
    {a : 1e21, b : 1e-7, c : 1e-6, d : Infinity, e : NaN, f : -0},
    '\"\\/\n\t\u0000\u2028\u2029',
);
for (const input of values)
    for (const mode of ["identity",
                        "double",
                        "delete",
                        "rootUndefined",
                        "throw",
                        "list",
                        "emptyList",
    ])
        for (const space of [0, 2, 20, -1, 1.9, "--", "abcdefghijk"]) {
            const calls = [];
            const replacer = function(key, value) {
                calls.push(key);
                if (mode === "throw" && key === "")
                    throw new Error("Replacer failed");
                if (mode === "double" && typeof value === "number")
                    return value * 2;
                if (mode === "delete" && (key === "drop" || key === "a" || value === "drop"))
                    return undefined;
                if (mode === "rootUndefined" && key === "")
                    return undefined;
                return value;
            };
            const config = {
                space,
                replacer : mode === "list"        ? [ "b", "a", "2", "a", "nested" ]
                           : mode === "emptyList" ? []
                                                  : replacer,
            };
            const r = v.safeParse(v.pipe(v.unknown(), v.stringifyJson(config)), input),
                  issue = r.issues?.[0];
            // Input numeric non-finite values are tagged, preserving their original JS type.
            const encode = (x) =>
                typeof x === "number" ? Number.isNaN(x)    ? {$number : "NaN"}
                                        : x === Infinity   ? {$number : "Infinity"}
                                        : x === -Infinity  ? {$number : "-Infinity"}
                                        : Object.is(x, -0) ? {$number : "-0"}
                                                           : x
                : Array.isArray(x)    ? x.map(encode)
                : x && typeof x === "object"
                    ? Object.fromEntries(Object.entries(x).map(([ k, v ]) => [k, encode(v)]))
                    : x;
            stringify.push({
                input : encode(input),
                mode,
                space,
                success : r.success,
                output : r.success ? r.output : "",
                received : issue?.received ?? "",
                message : issue?.message ?? "",
                code : issue?.type ?? "",
                calls,
            });
        }
writeReferenceFixture('json_config', {parse, stringify});
fs.writeFileSync(
    "tests/fixtures/json/json_config_differential.sources.json",
    JSON.stringify(
        {
            node : process.version,
            revision : cp.execFileSync("git", [ "-C", process.argv[2], "rev-parse", "HEAD" ], {
                             encoding : "utf8"
                         }).trim(),
            parse : parse.length,
            stringify : stringify.length,
            scope :
                "Reviver postorder/context.source, deletion/root undefined, replacer preorder/errors, property-list selection/order, indentation and non-finite/negative-zero binary64 serialization. Array holes are compared through a JSON projection.",
        },
        null,
        2,
        ) +
        "\n",
);
console.log(`${parse.length} parse and ${stringify.length} stringify outcomes`);
