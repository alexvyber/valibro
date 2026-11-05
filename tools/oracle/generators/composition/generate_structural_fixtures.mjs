import {loadValibot} from '../../shared/reference.mjs';
import {writeReferenceFixture} from '../../shared/native_cases.mjs';
// Maintainer-only: node tools/oracle/generators/composition/generate_structural_fixtures.mjs UPSTREAM_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
const root = path.resolve(process.argv[2]);
const v = await loadValibot();
export function schema(d) {
    const kind = d.kind;
    if (kind === "convertNumber")
        return v.pipe(v.string(), v.toNumber());
    if ([ "string", "number", "boolean", "unknown", "never", "null" ].includes(kind)) {
        let base = v[kind]();
        for (const a of d.actions ?? [])
            base = v.pipe(base, a.value === undefined ? v[a.name]() : v[a.name](a.value));
        return base;
    }
    if (kind === "literal")
        return v.literal(d.value);
    if (kind === "picklist")
        return v.picklist(d.values);
    if ([ "object", "strictObject", "looseObject" ].includes(kind))
        return v[kind](
            Object.fromEntries(Object.entries(d.entries).map(([ k, s ]) => [k, schema(s)])));
    if (kind === "objectWithRest")
        return v.objectWithRest(
            Object.fromEntries(Object.entries(d.entries).map(([ k, s ]) => [k, schema(s)])),
            schema(d.rest),
        );
    if (kind === "array")
        return v.array(schema(d.item));
    if ([ "tuple", "strictTuple", "looseTuple" ].includes(kind))
        return v[kind](d.items.map(schema));
    if (kind === "tupleWithRest")
        return v.tupleWithRest(d.items.map(schema), schema(d.rest));
    if (kind === "record")
        return v.record(schema(d.key), schema(d.value));
    if ([ "union", "intersect" ].includes(kind))
        return v[kind](d.options.map(schema));
    if (kind === "variant")
        return v.variant(d.key, d.options.map(schema));
    if ([ "optional", "exactOptional", "nullable", "nullish" ].includes(kind))
        return "default" in d ? v[kind](schema(d.wrapped), d.default) : v[kind](schema(d.wrapped));
    if ([ "partial", "required" ].includes(kind))
        return "keys" in d ? v[kind](schema(d.wrapped), d.keys) : v[kind](schema(d.wrapped));
    if ([ "nonOptional", "nonNullable", "nonNullish", "keyof" ].includes(kind))
        return v[kind](schema(d.wrapped));
    if ([ "pick", "omit" ].includes(kind))
        return v[kind](schema(d.wrapped), d.keys);
    if (kind === "fallback")
        return v.fallback(schema(d.wrapped), d.value);
    throw new Error(kind);
}
if (import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
    const s = {kind : "string", actions : [ {name : "trim"}, {name : "minLength", value : 2} ]};
    const n = {kind : "number", actions : [ {name : "integer"}, {name : "minValue", value : 0} ]};
    const obj = {
        kind : "object",
        entries : {
            name : s,
            age : n,
            enabled : {kind : "optional", wrapped : {kind : "boolean"}, default : true},
        },
    };
    const specs = [
        s,
        n,
        {kind : "boolean"},
        {kind : "unknown"},
        {kind : "never"},
        {kind : "null"},
        {kind : "literal", value : "a"},
        {kind : "picklist", values : [ "a", "b" ]},
        obj,
        ...["strictObject", "looseObject"].map((kind) => ({...obj, kind})),
        {...obj, kind : "objectWithRest", rest : {kind : "boolean"}},
        {kind : "array", item : s},
        ...["tuple", "strictTuple", "looseTuple"].map((kind) => ({kind, items : [ s, n ]})),
        {kind : "tupleWithRest", items : [ s ], rest : n},
        {kind : "tuple", items : [ {kind : "optional", wrapped : s, default : "ok"} ]},
        {kind : "record", key : {kind : "string", actions : [ {name : "toLowerCase"} ]}, value : n},
        {kind : "union", options : [ s, n ]},
        {
            kind : "union",
            options : [
                {kind : "literal", value : "a"},
                {kind : "literal", value : "b"},
            ],
        },
        {
            kind : "union",
            options : [
                {kind : "string", actions : [ {name : "minLength", value : 4} ]},
                {kind : "string", actions : [ {name : "maxLength", value : 1} ]},
            ],
        },
        {
            kind : "intersect",
            options : [
                {kind : "object", entries : {name : s}},
                {kind : "object", entries : {age : n}},
            ],
        },
        {
            kind : "variant",
            key : "type",
            options : [
                {kind : "object", entries : {type : {kind : "literal", value : "a"}, name : s}},
                {kind : "object", entries : {type : {kind : "literal", value : "b"}, age : n}},
            ],
        },
        ...["optional", "exactOptional", "nullable", "nullish"].flatMap(
            (kind) => [{kind, wrapped : s},
                       {kind, wrapped : s, default : "ok"},
    ]),
        ...["nonOptional", "nonNullable", "nonNullish"].map(
            (kind) => ({
                kind,
                wrapped : {kind : "nullish", wrapped : s},
            })),
        ...["pick", "omit"].map((kind) => ({kind, wrapped : obj, keys : [ "name" ]})),
        ...["partial", "required", "keyof"].map((kind) => ({kind, wrapped : obj})),
        {kind : "fallback", wrapped : s, value : "ok"},
        {kind : "object", entries : {a : {kind : "nullable", wrapped : s, default : "ok"}}},
        {kind : "array", item : {kind : "object", entries : {a : s}}},
    ];
    const inputs = [
        null,
        false,
        true,
        0,
        1,
        -1,
        1.5,
        "",
        "a",
        " hi ",
        "abc",
        "123",
        [],
        [ "hi" ],
        [ "hi", 1 ],
        [ "hi", 1, true ],
        [ "x", "bad" ],
        {},
        {name : " hi ", age : 42},
        {name : 1, age : -1},
        {name : "hi", age : 1, extra : true},
        {name : "hi", age : 1, extra : 5},
        {name : "hi"},
        {a : null},
        {a : " hi "},
        {A : 1, B : -1},
        {type : "a", name : " hi "},
        {type : "b", age : 42},
        [ {a : " hi "} ],
        [ {a : 1} ],
        {name : "hi", age : 1, enabled : null},
    ];
    const rows = [];
    for (const spec of specs)
        for (const input of inputs)
            for (const abortEarly of [false, true]) {
                const r = v.safeParse(schema(spec), input, {abortEarly});
                rows.push({
                    schema : spec,
                    input,
                    abort_early : abortEarly,
                    success : r.success,
                    ...(r.success ? {output : r.output} : {
                        codes : r.issues.map((i) => i.type),
                        paths : r.issues.map((i) => i.path?.map((p) => p.key) ?? []),
                    }),
                });
            }
    writeReferenceFixture('structural', rows, {indent: 4});
    console.log(
        `${rows.length} structural cases from Valibot ${
            JSON.parse(fs.readFileSync(path.join(root, "library/package.json"))).version}`,
    );
}
