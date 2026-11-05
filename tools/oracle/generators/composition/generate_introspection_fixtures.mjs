import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/composition/generate_introspection_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
import {schema} from "./generate_structural_fixtures.mjs";
const v = await loadValibot();
const descriptors = JSON.parse(
                            fs.readFileSync("tests/fixtures/composition/composition_differential.json"),
                            )
                        .descriptors;
const project = (x) =>
    JSON.parse(JSON.stringify(x, (_key, value) => (value === undefined ? null : value)));
const rows = descriptors.map((d, id) => {
    const s = schema(d);
    const def = v.getDefault(s), fallback = v.getFallback(s);
    return {
        schema_id : id,
        has_default : def !== undefined,
        default : project(def),
        has_fallback : fallback !== undefined,
        fallback : project(fallback),
        defaults : project(v.getDefaults(s)),
        fallbacks : project(v.getFallbacks(s)),
    };
});
writeReferenceFixture('introspection', rows);
console.log(rows.length + " introspection outcomes");
