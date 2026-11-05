import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/collections/generate_array_callback_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const rows = [];
for (const name of ["map", "filter", "find", "reduce", "every", "some", "check"])
    for (const input of [[], [ 0 ], [ 1, 1 ], [ 1, 2, 1 ], [ -1, 0, 2, 2 ], [ 3, 2, 1 ]])
        for (const abortEarly of [false, true])
            for (const abortPipeEarly of [false, true]) {
                const calls = [];
                const predicate = (item, index, array) => {
                    calls.push({item, index, array : [...array ]});
                    return array.indexOf(item) === index && item > 0;
                };
                const action = name === "map"      ? v.mapItems((item, index, array) => {
                    predicate(item, index, array);
                    return item + array.length + index;
                })
                               : name === "filter" ? v.filterItems(predicate)
                               : name === "find"   ? v.findItem(predicate)
                               : name === "reduce"
                                   ? v.reduceItems(
                                         (acc, item, index, array) => {
                                             predicate(item, index, array);
                                             return acc + item * array.length + index;
                                         },
                                         10)
                               : name === "every" ? v.everyItem(predicate)
                               : name === "some"  ? v.someItem(predicate)
                                                  : v.checkItems(predicate);
                const result = v.safeParse(v.pipe(v.array(v.number()), action), input, {
                    abortEarly,
                    abortPipeEarly,
                });
                rows.push({
                    name,
                    input,
                    abort_early : abortEarly,
                    abort_pipe_early : abortPipeEarly,
                    calls,
                    success : result.success,
                    output : result.output ?? null,
                    issues : (result.issues ?? []).map((i) => ({
                                                           code : i.type,
                                                           message : i.message,
                                                           path : i.path?.map((p) => p.key) ?? [],
                                                       })),
                });
            }
writeReferenceFixture('array_callback', rows);
console.log(rows.length + " array callback outcomes");
