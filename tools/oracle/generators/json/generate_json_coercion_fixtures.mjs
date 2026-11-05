import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {filterNativeDateRows} from '../../shared/native_scope.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/json/generate_json_coercion_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
process.env.TZ = "UTC";
const inputs = [
    null,
    true,
    false,
    0,
    -0,
    1,
    2,
    -1,
    1.5,
    NaN,
    Infinity,
    -Infinity,
    "",
    " ",
    "true",
    "TRUE",
    "false",
    "1",
    "0",
    "yes",
    "OFF",
    "NaN",
    "0x20",
    "2024-01-01T00:00:00Z",
    [],
    [ null ],
    [ true ],
    [ 1 ],
    [ 0 ],
    [ 1, 2 ],
    [ [ 1 ] ],
    [ [], [] ],
    [ {} ],
    {},
    {a : 1},
    {toString : 7},
    {valueOf : 3},
    [ {toString : null} ],
];
const encode = (x) => typeof x === "number" ? Number.isNaN(x)    ? {$number : "NaN"}
                                              : x === Infinity   ? {$number : "Infinity"}
                                              : x === -Infinity  ? {$number : "-Infinity"}
                                              : Object.is(x, -0) ? {$number : "-0"}
                                                                 : x
                      : Array.isArray(x)    ? x.map(encode)
                      : x && typeof x === "object"
                          ? Object.fromEntries(Object.entries(x).map(([ k, v ]) => [k, encode(v)]))
                          : x;
const rows = [];
for (const action of ["toNumber", "toBigint", "toBoolean", "toString", "toDate", "parseBoolean"])
    for (const mode of ["default", "factory", "config"]) {
        const message = mode === "factory" ? "Factory message" : undefined;
        const schema = v.pipe(
            v.unknown(),
            action === "parseBoolean" ? v.parseBoolean(undefined, message) : v[action](message),
        );
        for (const input of inputs) {
            const r = v.safeParse(schema, input,
                                  mode === "config" ? {message : "Config message"} : {}),
                  issue = r.issues?.[0];
            rows.push({
                action,
                input : encode(input),
                mode,
                success : r.success,
 nan_output: action === "toNumber" && Number.isNaN(r.output),
                output : r.success
                             ? action === "toDate" ? String(r.output.getTime()) : String(r.output)
                             : "",
                expected : issue?.expected ?? "",
                received : issue?.received ?? "",
                message : issue?.message ?? "",
                code : issue?.type ?? "",
            });
        }
    }
rows.splice(0,rows.length,...filterNativeDateRows('json_coercion',rows));
writeReferenceFixture('json_coercion', rows);
console.log(rows.length + " JSON coercion outcomes");
