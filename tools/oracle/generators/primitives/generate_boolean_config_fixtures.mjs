import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/primitives/generate_boolean_config_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const rows = [];
const encode = (x) => typeof x === "number" && Number.isNaN(x) ? {$number : "NaN"}
                      : Array.isArray(x)                       ? x.map(encode)
                                                               : x;
for (const truthy of [[], [ "YES", "İ", "Σ" ], [ true, 1, NaN, null ], [ "x", 0, false ]])
    for (const falsy of [[], [ "NO", "i̇", "ς" ], [ false, 0, NaN, null ], [ "x", 1, true ]])
        for (const input of ["YES",
                             "yes",
                             "İ",
                             "i̇",
                             "Σ",
                             "σ",
                             "ς",
                             "NO",
                             "no",
                             "x",
                             "",
                             null,
                             true,
                             false,
                             0,
                             1,
                             2,
                             NaN,
        ]) {
            const r = v.safeParse(v.pipe(v.unknown(), v.parseBoolean({truthy, falsy})), input);
            rows.push({
                truthy : encode(truthy),
                falsy : encode(falsy),
                input : encode(input),
                success : r.success,
                output : r.success ? r.output : null,
                issues : (r.issues ?? []).map((i) => ({
                                                  expected : i.expected,
                                                  received : i.received,
                                                  message : i.message,
                                              })),
            });
        }
writeReferenceFixture('boolean_config', rows);
console.log(rows.length + " configured boolean outcomes");
