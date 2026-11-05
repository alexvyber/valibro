import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/collections/generate_native_collection_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const rows = [];
for (const domain of ["array", "set", "map", "record"])
    for (const values of [[], [ 1 ], [ -1 ], [ 1, -1, 2.5 ], [ 0, 2, 0, -3 ], [ 3.5, 2, 1 ]])
        for (const transform of [false, true])
            for (const abortEarly of [false, true])
                for (const abortPipeEarly of [false, true]) {
                    const items =
                        transform ? v.pipe(v.number(), v.minValue(0), v.toMinValue(1), v.integer())
                                  : v.pipe(v.number(), v.minValue(0), v.integer());
                    const entries = values.map((n, i) => [(i % 2 === 0 ? " k" : "x") + i, n]);
                    const keys = transform ? v.pipe(v.string(), v.minLength(3), v.trim())
                                           : v.pipe(v.string(), v.minLength(3));
                    const schema = domain === "array" ? v.array(items)
                                   : domain === "set" ? v.set(items)
                                   : domain === "map" ? v.map(keys, items)
                                                      : v.record(keys, items);
                    const input = domain === "array" ? values
                                  : domain === "set" ? new Set(values)
                                  : domain === "map" ? new Map(entries)
                                                     : Object.fromEntries(entries);
                    const d = schema["~run"]({value : input}, {abortEarly, abortPipeEarly});
                    const output = domain === "set"   ? [...d.value ]
                                   : domain === "map" ? [...d.value ]
                                                      : d.value;
                    const flat = d.issues ? v.flatten(d.issues) : {};
                    rows.push({
                        domain,
                        values,
                        entries,
                        transform,
                        abort_early : abortEarly,
                        abort_pipe_early : abortPipeEarly,
                        typed : d.typed,
                        output,
                        issues : (d.issues ?? []).map((i) => ({
                                                          code : i.type,
                                                          expected : i.expected ?? "",
                                                          received : i.received,
                                                          message : i.message,
                                                          dot : v.getDotPath(i) ?? "",
                                                      })),
                        flat : {
                            root : flat.root ?? [],
                            nested : flat.nested ?? {},
                            other : flat.other ?? []
                        },
                    });
                }
writeReferenceFixture('native_collection', rows);
console.log(rows.length + " native collection outcomes");
