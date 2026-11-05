import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/execution/generate_pipeline_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const rows = [];
for (const mode of ["validation",
                    "transform_after",
                    "raw_after",
                    "raw_after_type",
                    "raw_transform", "raw_transform_to",
])
    for (const input of ["", "a", "abc", "abcdz", " ab ", "ß", 0, null])
        for (const abortEarly of [false, true])
            for (const abortPipeEarly of [false, true])
                for (const lang of ["en", "ru"]) {
                    const calls = [];
                    const trace = ({dataset, config}) => calls.push({
                        typed : !!dataset.typed,
                        value : dataset.value,
                        issues : dataset.issues?.length ?? 0,
                        lang : config.lang,
                    });
                    const raw = v.rawCheck((ctx) => {
                        trace(ctx);
                        if (ctx.dataset.value === "a")
                            ctx.addIssue({message : "Raw custom"});
                    });
                    const transform = v.rawTransform((ctx) => {
                        trace(ctx);
                        if (ctx.dataset.value === "a")
                            ctx.addIssue({message : "Transform custom"});
                        return ctx.dataset.value.toUpperCase();
                    });
                    const schema =
                        mode === "validation" ? v.pipe(v.string(), v.minLength(3), v.endsWith("z"))
                        : mode === "transform_after" ? v.pipe(v.string(), v.minLength(3), v.trim())
                        : mode === "raw_after"       ? v.pipe(v.string(), v.minLength(3), raw)
                        : mode === "raw_after_type" ? v.pipe(v.number(), raw)
                                                    : v.pipe(v.string(), transform, v.minLength(3));
                    const config = {abortEarly, abortPipeEarly, lang, message : "Config " + lang};
                    const result = schema["~run"]({value : input}, config);
                    rows.push({
                        mode,
                        input,
                        abort_early : abortEarly,
                        abort_pipe_early : abortPipeEarly,
                        lang,
                        typed : !!result.typed,
                        value : result.value,
                        codes : result.issues?.map((i) => i.type) ?? [],
                        messages : result.issues?.map((i) => i.message) ?? [],
                        calls,
                    });
                }
writeReferenceFixture('pipeline', rows);
console.log(rows.length + " pipeline outcomes");
