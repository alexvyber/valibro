import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/execution/generate_message_context_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const rows = [];
for (const name of ["schema",
                    "runtime_type",
                    "check",
                    "format",
                    "convert",
                    "multiple",
                    "words",
                    "url",
                    "regex",
                    "custom_check",
])
    for (const mode of ["factory", "specific", "schema", "config", "global", "default"])
        for (const lang of ["", "ru"])
            for (const abortEarly of [false, true])
                for (const abortPipeEarly of [false, true]) {
                    const calls = [];
                    const callback = (provider) => (issue) => {
                        calls.push({
                            provider,
                            kind : issue.kind,
                            code : issue.type,
                            lang : issue.lang ?? "",
                            abort_early : issue.abortEarly ?? false,
                            abort_pipe_early : issue.abortPipeEarly ?? false,
                            expected : issue.expected ?? "",
                            received : issue.received,
                            message : issue.message,
                        });
                        return "Selected " + provider;
                    };
                    const factory = mode === "factory" ? callback("factory") : undefined;
                    const reference = {
                        schema : v.literal,
                        runtime_type : v.string,
                        check : v.minLength,
                        format : v.email,
                        convert : v.toBigint,
                        multiple : v.multipleOf,
                        words : v.words,
                        url : v.url,
                        regex : v.regex,
                        custom_check : v.check,
                    }[name];
                    if (mode === "specific")
                        v.setSpecificMessage(reference, callback("specific"), lang);
                    if (mode === "schema")
                        v.setSchemaMessage(callback("schema"), lang);
                    if (mode === "global")
                        v.setGlobalMessage(callback("global"), lang);
                    const s = name === "schema"         ? v.literal("a", factory)
                              : name === "runtime_type" ? v.string(factory)
                              : name === "check"    ? v.pipe(v.string(), v.minLength(3, factory))
                              : name === "format"   ? v.pipe(v.string(), v.email(factory))
                              : name === "convert"  ? v.pipe(v.string(), v.toBigint(factory))
                              : name === "multiple" ? v.pipe(v.number(), v.multipleOf(2, factory))
                              : name === "url"      ? v.pipe(v.string(), v.url(factory))
                              : name === "regex"    ? v.pipe(v.string(), v.regex(/a/, factory))
                              : name === "custom_check"
                                  ? v.pipe(
                                        v.string(),
                                        v.check(() => false, factory),
                                        )
                                  : v.pipe(v.string(), v.words("en", 2, factory));
                    const input = name === "multiple" ? 3 : name === "runtime_type" ? 123 : "x";
                    const r = v.safeParse(s, input, {
                        lang,
                        abortEarly,
                        abortPipeEarly,
                        ...([ "factory", "specific", "schema", "config" ].includes(mode)
                                ? {message : callback("config")}
                                : {}),
                    });
                    rows.push({
                        name,
                        mode,
                        lang,
                        abort_early : abortEarly,
                        abort_pipe_early : abortPipeEarly,
                        input,
                        messages : r.issues.map((i) => i.message),
                        calls,
                    });
                    v.deleteSpecificMessage(reference, lang);
                    v.deleteSchemaMessage(lang);
                    v.deleteGlobalMessage(lang);
                }
writeReferenceFixture('message_context', rows);
console.log(rows.length + " message context outcomes");
