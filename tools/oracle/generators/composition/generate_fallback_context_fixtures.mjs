import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/composition/generate_fallback_context_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const rows = [];
for (const input of ["", " x ", "xxx", "abcde", "  xx  "])
    for (const lang of ["", "ru"])
        for (const abortEarly of [false, true])
            for (const abortPipeEarly of [false, true]) {
                const calls = [];
                const settings = {lang, abortEarly, abortPipeEarly};
                const callback = (dataset, config) => {
                    const call = {
                        present : !!dataset,
                        value : dataset?.value ?? "",
                        typed : !!dataset?.typed,
                        codes : dataset?.issues?.map((i) => i.type) ?? [],
                        lang : config?.lang ?? "",
                    };
                    calls.push(call);
                    return dataset
                               ? `${call.value}:${call.typed}:${call.codes.join(",")}:${call.lang}`
                               : `none:${call.lang}`;
                };
                const s = v.fallback(
                    v.pipe(v.string(), v.trim(), v.minLength(3), v.maxLength(4)),
                    callback,
                );
                const introspection = v.getFallback(s, undefined, settings);
                const result = v.safeParse(s, input, settings);
                rows.push({
                    input,
                    lang,
                    abort_early : abortEarly,
                    abort_pipe_early : abortPipeEarly,
                    introspection,
                    output : result.output,
                    calls,
                });
            }
writeReferenceFixture('fallback_context', rows);
console.log(rows.length + " fallback context outcomes");
