import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/collections/generate_collection_action_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const rows = [];
function capture(domain, action, requirement, input, value, mode, check) {
    const r = v.safeParse(
        v.pipe(v.unknown(), check),
        value,
        mode === "config" ? {message : "Config message"} : {},
    );
    rows.push({
        domain,
        action,
        requirement,
        input,
        mode,
        success : r.success,
        issues : (r.issues ?? []).map((i) => ({
                                          code : i.type,
                                          expected : i.expected ?? "",
                                          received : i.received,
                                          message : i.message,
                                          path : i.path?.map((p) => p.key) ?? [],
                                      })),
    });
}
for (const mode of ["default", "factory", "config"]) {
    const message = mode === "factory" ? "Factory message" : undefined;
    for (const domain of ["object", "map", "set", "blob", "file"])
        for (const n of [0, 1, 3]) {
            const input = domain === "object"
                              ? Object.fromEntries(Array.from({length : n}, (_, i) => ["k" + i, i]))
                          : domain === "map" ? Array.from({length : n}, (_, i) => ["k" + i, i])
                          : domain === "set" ? Array.from({length : n}, (_, i) => i)
                                             : "x".repeat(n);
            const value = domain === "object" ? input
                          : domain === "map"  ? new Map(input)
                          : domain === "set"  ? new Set(input)
                          : domain === "blob"
                              ? new Blob([ input ], {type : "text/plain"})
                              : new File([ input ], "x", {type : "text/plain", lastModified : 0});
            const family = domain === "object" ? "Entries" : "Size";
            for (const prefix of ["", "min", "max", "not"])
                for (const r of [-1, 0, 1, 3]) {
                    const action =
                        prefix ? prefix + family : family[0].toLowerCase() + family.slice(1);
                    capture(domain, action, r, input, value, mode, v[action](r, message));
                }
            if (domain === "blob" || domain === "file")
                for (const r of [[],
                                 [ "text/plain" ],
                                 [ "image/png" ],
                                 [ "text/plain", "image/png", "text/plain" ],
                ])
                    capture(domain, "mimeType", r, input, value, mode, v.mimeType(r, message));
        }
    for (const input of [[], [ 1 ], [ 0, 1 ], [ 1, 2, 3 ], [ -1, -2 ], [ 2, 4 ]]) {
        for (const action of ["everyItem", "someItem", "checkItems"])
            capture(
                "array",
                action,
                null,
                input,
                input,
                mode,
                v[action]((x, i) => x % 2 === 0 && i < 3, message),
            );
        for (const action of ["includes", "excludes"])
            for (const r of [0, 1, 2])
                capture("array", action, r, input, input, mode, v[action](r, message));
    }
}
writeReferenceFixture('collection_action', rows);
console.log(rows.length + " collection action outcomes");
