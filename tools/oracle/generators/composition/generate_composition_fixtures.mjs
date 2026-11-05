import {writeReferenceFixture} from '../../shared/native_cases.mjs';
// node tools/oracle/generators/composition/generate_composition_fixtures.mjs PINNED_VALIBOT_CHECKOUT
// Deterministic nested compositions, missing entries and four abort settings.
import fs from "node:fs";
import cp from "node:child_process";
import {schema} from "./generate_structural_fixtures.mjs";
let seed = 0x5eedc0de;
const random = (n) => {
    seed ^= seed << 13;
    seed ^= seed >>> 17;
    seed ^= seed << 5;
    return (seed >>> 0) % n;
};
const str = {
    kind : "string",
    actions : [ {name : "trim"}, {name : "minLength", value : 2}, {name : "maxLength", value : 4} ],
};
const num = {
    kind : "number",
    actions : [ {name : "integer"}, {name : "minValue", value : 0} ]
};
const atoms = [
    str,
    num,
    {kind : "string"},
    {kind : "number"},
    {kind : "boolean"},
    {kind : "unknown"},
    {kind : "never"},
    {kind : "null"},
    {kind : "literal", value : "a"},
    {kind : "literal", value : 1},
    {kind : "picklist", values : [ "a", "b" ]},
    {kind : "picklist", values : []},
    {kind : "string", actions : [ {name : "toLowerCase"}, {name : "minLength", value : 2} ]},
];
const descriptors = [...atoms ];
const kinds = [
    "array",       "object",        "strictObject", "looseObject",    "tuple",
    "strictTuple", "looseTuple",    "record",       "union",          "intersect",
    "optional",    "exactOptional", "nullable",     "nullish",        "nonOptional",
    "nonNullable", "nonNullish",    "fallback",     "objectWithRest", "tupleWithRest",
];
function nested(depth) {
    if (depth === 0 || random(4) === 0)
        return atoms[random(atoms.length)];
    const kind = kinds[random(kinds.length)];
    const child = () => nested(depth - 1);
    if ([ "optional", "exactOptional", "nullable", "nullish" ].includes(kind))
        return random(2) ? {kind, wrapped : child()}
                         : {kind, wrapped : child(), default : random(2) ? " default " : null};
    if ([ "nonOptional", "nonNullable", "nonNullish" ].includes(kind))
        return {kind, wrapped : child()};
    if (kind === "fallback")
        return {kind, wrapped : child(), value : random(2) ? "fallback" : null};
    if (kind === "array")
        return {kind, item : child()};
    if (kind === "record")
        return {
            kind,
            key : random(2) ? {kind : "string", actions : [ {name : "toLowerCase"} ]}
                            : {kind : "picklist", values : [ "a", "b" ]},
            value : child(),
        };
    if ([ "tuple", "strictTuple", "looseTuple", "tupleWithRest" ].includes(kind))
        return {
            kind,
            items : Array.from({length : random(4)}, child),
            ...(kind === "tupleWithRest" ? {rest : child()} : {}),
        };
    if ([ "union", "intersect" ].includes(kind))
        return {kind, options : Array.from({length : random(3) + 1}, child)};
    return {
        kind,
        entries :
            Object.fromEntries([ "a", "b", "c" ].slice(0, random(4)).map((k) => [k, child()])),
        ...(kind === "objectWithRest" ? {rest : child()} : {}),
    };
}
for (let i = 0; i < 500; i++)
    descriptors.push(nested(4));
const object = {
    kind : "object",
    entries : {a : str, b : num, c : {kind : "optional", wrapped : str, default : "ok"}},
};
for (const kind of ["partial", "required", "pick", "omit"])
    descriptors.push({kind, wrapped : object, keys : [ "a" ]});
for (const kind of ["object", "strictObject", "looseObject", "objectWithRest"]) {
    descriptors.push({...object, kind, ...(kind === "objectWithRest" ? {rest : num} : {})});
    descriptors.push({
        kind,
        entries :
            JSON.parse('{"10":{"kind":"string"},"2":{"kind":"number"},"a":{"kind":"boolean"}}'),
        ...(kind === "objectWithRest" ? {rest : num} : {}),
    });
}
for (const key of ["type", "kind"])
    descriptors.push({
        kind : "variant",
        key,
        options : [ "a", "b" ].map((value) => ({
                                       kind : "object",
                                       entries : {[key] : {kind : "literal", value}, value : str},
                                   })),
    });
descriptors.push(
    {kind : "union", options : []},
    {kind : "intersect", options : []},
    {kind : "record", key : {kind : "convertNumber"}, value : {kind : "unknown"}},
);
descriptors.push({
    kind : "variant",
    key : "type",
    options : [
        {kind : "object", entries : {type : {kind : "literal", value : "a"}, value : str}},
        {
            kind : "variant",
            key : "kind",
            options : [
                {
                    kind : "object",
                    entries : {
                        type : {kind : "literal", value : "b"},
                        kind : {kind : "literal", value : 1},
                        value : num,
                    },
                },
                {
                    kind : "object",
                    entries : {
                        type : {kind : "literal", value : "b"},
                        kind : {kind : "literal", value : 2},
                        value : str,
                    },
                },
            ],
        },
        {
            kind : "object",
            entries : {type : {kind : "literal", value : "b"}, value : {kind : "boolean"}},
        },
    ],
});
const inputs = [
    null,
    false,
    true,
    0,
    1,
    -1,
    0.5,
    "",
    "a",
    "b",
    " aa ",
    "12345",
    [],
    [ null ],
    [ "a" ],
    [ " aa ", 1 ],
    [ "a", -1, null ],
    {},
    {a : null},
    {a : " aa "},
    {a : " aa ", b : 1},
    {a : 0, b : -1, c : false},
    {a : "aaa", b : 2, c : "ok", extra : 1},
    {a : [], b : {}, c : null},
    {a : {a : "x"}, b : [ "a", 1 ]},
    {2 : "x", 10 : 1, a : false},
    JSON.parse('{"__proto__":1,"prototype":2,"constructor":3,"a":4}'),
    {type : "a", value : " aa "},
    {type : "b", value : "x"},
    {kind : "a", value : " aa "},
    [ "a", "b", "c", "d" ],
    [ {a : 1}, {a : " aa "} ],
];
function sample(d) {
    if (!d)
        return null;
    if (d.kind === "string")
        return " ab ";
    if (d.kind === "number")
        return 1;
    if (d.kind === "boolean")
        return true;
    if (d.kind === "literal")
        return d.value;
    if (d.kind === "picklist")
        return d.values[0] ?? null;
    if (d.entries)
        return Object.fromEntries(Object.entries(d.entries).map(([ k, c ]) => [k, sample(c)]));
    if (d.items)
        return d.items.map(sample);
    if (d.item)
        return [ sample(d.item) ];
    if (d.options)
        return sample(d.options[0]);
    if (d.wrapped)
        return sample(d.wrapped);
    if (d.kind === "record")
        return {a : sample(d.value)};
    return null;
}
const normalize = (issues) => (issues ?? []).map((i) => ({
                                                     code : i.type,
                                                     path : (i.path ?? []).map((p) => p.key),
                                                     issues : normalize(i.issues),
                                                 }));
const detailRows = [];
const detailMap = new Map();
const detailed = (issues) => (issues ?? []).map((i) => ({
                                                    code : i.type,
                                                    kind : i.kind,
                                                    expected : i.expected ?? "",
                                                    received : i.received,
                                                    message : i.message,
                                                    path : (i.path ?? []).map((p) => p.key),
                                                    issues : detailed(i.issues),
                                                }));
function details(issues) {
    const value = detailed(issues), key = JSON.stringify(value);
    if (!detailMap.has(key)) {
        detailMap.set(key, detailRows.length);
        detailRows.push(value);
    }
    return detailMap.get(key);
}
const rows = [];
for (let id = 0; id < descriptors.length; id++) {
    const d = descriptors[id], s = schema(d), value = sample(d);
    const values = [
        ...inputs,
        value,
        {type : "b", kind : 1, value : 2},
        {type : "b", kind : 2, value : " aa "},
        {type : "b", kind : 3, value : "x"},
        {type : "a", kind : 1, value : true},
    ];
    if (value && typeof value === "object" && !Array.isArray(value)) {
        for (const key of Object.keys(value)) {
            const missing = {...value};
            delete missing[key];
            values.push(missing);
        }
    }
    for (const input of values)
        for (const abortEarly of [false, true])
            for (const abortPipeEarly of [false, true]) {
                const result =
                    s["~run"]({value : structuredClone(input)}, {abortEarly, abortPipeEarly});
                rows.push({
                    schema_id : id,
                    input,
                    abort_early : abortEarly,
                    abort_pipe_early : abortPipeEarly,
                    typed : !!result.typed,
                    success : !result.issues,
                    issue_detail : details(result.issues),
                    issues : normalize(result.issues),
                    output : result.value,
                });
            }
}
const target = "tests/fixtures/composition/composition_differential.json";
writeReferenceFixture('composition', {descriptors, rows, issue_details : detailRows});
fs.writeFileSync(
    target.replace(".json", ".sources.json"),
    JSON.stringify(
        {
            node : process.version,
            upstream : cp.execFileSync("git", [ "-C", process.argv[2], "rev-parse", "HEAD" ], {
                             encoding : "utf8"
                         }).trim(),
            seed : "0x5eedc0de",
            descriptors : descriptors.length,
            outcomes : rows.length,
            unique_issue_trees : detailRows.length,
            scope :
                "JSON-expressible inputs; all JSON-projected dataset outputs, typed state, complete recursive issue fields; four abort settings. Missing entries and recursive compositions included.",
        },
        null,
        2,
        ) +
        "\n",
);
console.log(`${descriptors.length} descriptors; ${rows.length} outcomes`);
