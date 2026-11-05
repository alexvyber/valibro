import {loadValibot} from './shared/reference.mjs';
// Maintainer-only: node tools/oracle/generate_capability_inventory.mjs UPSTREAM_CHECKOUT
// An API availability inventory, not a behavioral-parity percentage.
import fs from "node:fs";
import path from "node:path";
import cp from "node:child_process";
import {pathToFileURL} from "node:url";
const upstream = path.resolve(process.argv[2]);
const root = path.resolve(import.meta.dirname, "../..");
const v = await loadValibot();
const snake = (s) => s.replace(/[A-Z]/g, (c) => "_" + c.toLowerCase());
const symbols = new Map();
for (const [namespace, directory] of [[ "valibro", root ],
                                      [ "valibro.json", path.join(root, "json") ],
]) {
    for (const name of fs.readdirSync(directory).filter(
             (n) => n.endsWith(".v") && (namespace !== "valibro" || (n === "valibro.v" || n.startsWith("api_"))))) {
        const source = fs.readFileSync(path.join(directory, name), "utf8");
        for (const m of source.matchAll(/pub fn (\w+)/g))
            symbols.set(`${namespace}.${m[1]}`, path.relative(root, path.join(directory, name)));
    }
}
const aliases = {
    ValiError : [ "types.ValidationError" ],
    any : [ "valibro.any_value", "valibro.json.any_value" ],
    assert: [ "valibro.assert_valid" ],
    await: [ "valibro.await_future" ],
    enum: [ "valibro.enum_schema" ],
    function: [ "valibro.function_schema" ],
    map: [ "valibro.map_schema" ],
    null: [ "valibro.null_schema", "valibro.json.null_value" ],
    undefined: [ "valibro.undefined_schema" ],
    void: [ "valibro.void_schema" ],
    is: [ "valibro.is_valid" ],
};
Object.assign(aliases, {
 parseJson:['valibro.parse_json','valibro.parse_json_with_config'],
 stringifyJson:['valibro.stringify_json','valibro.stringify_json_value','valibro.stringify_json_with_config','valibro.stringify_json_value_with_config','valibro.stringify_json_with_config_utf16'],
 parseBoolean:['valibro.parse_boolean','valibro.parse_boolean_from','valibro.parse_boolean_with_config','valibro.parse_boolean_with_values'],
 fallback:['valibro.fallback','valibro.fallback_fn','valibro.fallback_with_context','valibro.json.fallback'],
 getDefault:['valibro.get_default','valibro.get_default_with_context','valibro.json.get_default'],
 getFallback:['valibro.get_fallback','valibro.get_fallback_with_context','valibro.json.get_fallback'],
 rawCheck:['valibro.raw_check','valibro.raw_check_with_context'],
 rawTransform:['valibro.raw_transform','valibro.raw_transform_with_context','valibro.raw_transform_to_with_context']
});
for(const action of ['mapItems','filterItems','findItem','reduceItems','everyItem','someItem','checkItems']) {
 const name=snake(action);aliases[action]=[`valibro.${name}`,`valibro.${name}_with_array`];
}
const profiles = {
    forward: "Existing JSON map keys and integer array indexes; missing paths stop at the deepest existing prefix. No truthiness or simulated properties.",
    length: "Native Unicode scalar length, rather than UTF-16 units.",
    minLength: "Native Unicode scalar string lengths; native collection counts.",
    maxLength: "Native Unicode scalar string lengths; native collection counts.",
    notLength: "Native Unicode scalar string lengths; native collection counts.",
    startsWith: "Native UTF-8 prefixes with whole-code-point diagnostic fragments.",
    endsWith: "Native UTF-8 suffixes with whole-code-point diagnostic fragments.",
    trim: "V Unicode whitespace, without ECMAScript BOM trimming.",
    trimStart: "V Unicode whitespace.",
    trimEnd: "V Unicode whitespace.",
    record: "Native map iteration and ordinary keys, including constructor and __proto__.",
    looseObject: "Native map iteration and ordinary extra keys.",
    objectWithRest: "Native map iteration and ordinary extra keys.",
    words: "Native Unicode 17 default UAX #29 word boundaries; counts segments containing a Unicode letter or number. No locale or dictionary tailoring.",
    minWords: "Native Unicode 17 default word segmentation without locale dictionaries.",
    maxWords: "Native Unicode 17 default word segmentation without locale dictionaries.",
    notWords: "Native Unicode 17 default word segmentation without locale dictionaries.",
    url: "Native net.urllib absolute-URI validation with strict host/port/escape checks; no browser repair, IDNA conversion, or WHATWG normalization.",
    base64: "Native ASCII Base64 alphabet; JavaScript Unicode-folded letters are rejected. Two explicit format profile cases document this boundary.",
    regex: "Native V regex.pcre subset: stateless UTF-8 searches, native i/m/s modifiers and strict anchors; JavaScript regex grammar/state APIs are outside scope.",
    cache :
        "Bounded native LRU with expiration and controls. message_fn/identified_message provide stable callback identity; bare unidentified functions bypass caching.",
    date :
        "Native calendar validation for years -999999 through 999999; preserves native nanoseconds and has no mutable invalid-Date object.",
    toDate :
        "Native strict ISO calendar parsing with UTC defaults, explicit fixed offsets, nanosecond fractions, and native Date and epoch-millisecond conversions; null/boolean/collection conversions fail. Legacy JavaScript date strings and IANA timezone parsing are outside scope.",
    toNumber :
        "Exact native rounding for string/native/JSON scalars; collections and null require explicit conversion; Typed NumberProvider and DateProvider preserve native conversions without boxed primitive dispatch.",
    toBoolean : "Native string.bool(), numeric nonzero, collection/countable nonempty, and explicit BooleanProvider conversions. Unsupported structs and Dates produce issues.",
    toBigint : "Native big.Integer and typed to_bigint_from variants.",
    toString :
        "Binary64 number formatting and native UTC ISO Date display; Typed StringProvider supplies explicit string conversion; structs and collections retain V representation; no implicit comma joining.",
    parseJson : "Native JSON parser with reviver, source text, holder snapshots, explicit root deletion and opt-in binary64_numbers; V parser diagnostics.",
    stringifyJson : "Iterative native/JSON serialization, recursive struct field hooks with V JSON tags, presence-aware replacers, holder context, whitelist, optional depth guard, binary64 numbers and exact UTF-16 output.",
    values :
        "Native action codes/names remain explicit; native date equality includes nanosecond precision.",
    notValues :
        "Native action codes/names remain explicit; native date equality includes nanosecond precision.",
    instance :
        "Native type checking; JS class identity and instanceof are outside the V value model.",
    map : "map_schema supports native hash keys; entry_map supports arbitrary keys with explicit equality/identity.",
    set :
        "Insertion-ordered Set defaults to native equality and numeric SameValueZero; set_with and new_set_with accept explicit equality/identity.",
    unwrap :
        "Native and JSON unwrap return the original stored schema; unwrap_as checks alternate native inner signatures.",
};
const testFiles = fs.readdirSync(path.join(root, 'tests'), {recursive:true}).filter(name=>name.endsWith('_test.v'));
const differentialTest = name => {
 const found = testFiles.filter(file=>path.basename(file)===`${name}_differential_test.v`);
 if(found.length!==1)throw new Error(`Expected exactly one differential test for ${name}`);
 return 'tests/'+found[0].split(path.sep).join('/');
};
const evidence = {
    base64: ["tests/strings/string_formats_test.v", "tests/fixtures/strings/native_format_profile.json"],
    url : [ "tests/engines/url_test.v" ],
    regex : [ "tests/engines/native_regex_test.v", "tests/engines/regex_test.v" ],
    words : [ "tests/strings/native_words_test.v" ],
    minWords : [ "tests/strings/native_words_test.v" ],
    maxWords : [ "tests/strings/native_words_test.v" ],
    notWords : [ "tests/strings/native_words_test.v" ],
    multipleOf : [ "tests/primitives/numeric_checks_test.v", "tests/execution/runtime_errors_test.v" ],
    toDate : [ "tests/engines/native_dates_test.v" ],
    toNumber : [ "tests/engines/number_parity_test.v" ],
    toString : [ "tests/engines/number_parity_test.v" ],
    cache : [ "tests/execution/execution_test.v" ],
};
Object.assign(evidence, {
 parseJson:['tests/json/json_config_differential_test.v','tests/json/json_holder_differential_test.v'],
 stringifyJson:['tests/json/json_config_differential_test.v','tests/json/json_holder_differential_test.v'],
 parseBoolean:['tests/primitives/conversion_differential_test.v','tests/primitives/boolean_config_differential_test.v'],
 fallback:['tests/composition/fallback_context_differential_test.v'],
 getDefault:['tests/composition/default_context_differential_test.v','tests/composition/structural_parity_test.v'],
 getFallback:['tests/composition/fallback_context_differential_test.v','tests/composition/structural_parity_test.v'],
 value:['tests/strings/action_differential_test.v','tests/primitives/native_value_differential_test.v'],
 values:['tests/strings/action_differential_test.v','tests/primitives/native_value_differential_test.v'],
 minValue:['tests/strings/action_differential_test.v','tests/primitives/native_value_differential_test.v'],
 maxValue:['tests/strings/action_differential_test.v','tests/primitives/native_value_differential_test.v'],
 set:['tests/collections/native_collection_differential_test.v','tests/collections/dynamic_set_differential_test.v'],
 partialCheck:['tests/composition/custom_check_differential_test.v'],
 guard:['tests/composition/custom_check_differential_test.v'],
 flatten:['tests/execution/error_path_differential_test.v','tests/collections/native_collection_differential_test.v'],
 forward:['tests/execution/pipeline_differential_test.v'],
 safeParse:['tests/composition/presence_differential_test.v','tests/composition/structural_parity_test.v']
});
for(const action of ['mapItems','filterItems','findItem','reduceItems','everyItem','someItem','checkItems'])evidence[action]=['tests/collections/array_callback_differential_test.v'];
for(const action of ['object','array','tuple','record','union','intersect','variant','optional','nullable','nullish','partial','required'])evidence[action]=['tests/composition/structural_parity_test.v'];
Object.assign(aliases, {map:['valibro.map_schema','valibro.entry_map'], set:['valibro.set','valibro.set_with'], unwrap:['valibro.unwrap','valibro.unwrap_as']});
for(const name of ['optional','nullable','nullish','undefinedable','exactOptional']) {
 const native=snake(name); aliases[name]=[`valibro.${native}`,`valibro.${native}_with_default_state`,`valibro.json.${native}`];
 evidence[name]=[...(evidence[name]??[]),'tests/composition/default_state_audit_differential_test.v'];
}
for(const [name,tests] of Object.entries({
 unwrap:['wrapper_audit'],partial:['wrapper_audit'],required:['wrapper_audit'],pick:['wrapper_audit'],omit:['wrapper_audit'],
 stringifyJson:['json_runtime_audit','json_number_audit','native_hook_audit'],parseJson:['json_number_audit'],
 toNumber:['native_hook_audit'],toBigint:['native_hook_audit'],toString:['native_hook_audit'],toDate:['native_hook_audit'],
 cache:['cache_identity_audit'],safeParse:['raw_output_audit'],map:['entry_map_audit'],set:['entry_map_audit']
}))evidence[name]=[...(evidence[name]??[]),...tests.map(test=>differentialTest(test))];
for(const [name,tests] of Object.entries({
 set:['partial_equality'],map:['partial_equality'],safeParse:['partial_equality'],stringifyJson:['json_presence','struct_json']
}))evidence[name]=[...(evidence[name]??[]),...tests.map(test=>differentialTest(test))];
for(const name of ['number','finite','integer','safeInteger','multipleOf','minValue','maxValue','gtValue','ltValue','value','values','toMinValue','toMaxValue','toNumber','toBigint','toBoolean','parseBoolean','toDate','toString','stringifyJson'])
 evidence[name]=[...(evidence[name]??[]),'tests/primitives/numeric_representation_differential_test.v'];
for(const name of ['stringifyJson','safeParse'])evidence[name]=[...(evidence[name]??[]),'tests/json/json_interaction_differential_test.v'];
for(const name of ['stringifyJson','parseJson','optional','nullable','nullish'])evidence[name]=[...(evidence[name]??[]),'tests/json/maybe_json_differential_test.v'];
for(const name of ['stringifyJson','toNumber','toBigint','toBoolean','toDate','toString'])evidence[name]=[...(evidence[name]??[]),'tests/json/boxed_date_differential_test.v'];
for(const name of ['toNumber','toBigint','toBoolean','toDate','toString','parseBoolean'])evidence[name]=[...(evidence[name]??[]),'tests/primitives/maybe_conversion_differential_test.v'];
for(const name of ['toNumber','toBigint','toBoolean','toDate','toString'])evidence[name]=[...(evidence[name]??[]),'tests/primitives/native_array_conversions_test.v'];
for(const name of ['union','safeParse','array','map','set','pipe','fallback'])evidence[name]=[...(evidence[name]??[]),'tests/composition/native_union_differential_test.v'];
for(const name of ['date','safeParse','array'])evidence[name]=[...(evidence[name]??[]),'tests/primitives/native_date_validation_differential_test.v'];
for(const name of ['date','toDate','toString'])evidence[name]=[...(evidence[name]??[]),'tests/engines/native_dates_test.v'];
for(const name of ['toNumber','toBigint','toDate','toString','toBoolean','forward','parseJson','stringifyJson'])evidence[name]=[...(evidence[name]??[]),'tests/engines/native_simplification_test.v'];
const functions = Object.keys(v).filter(
    (name) => !name.startsWith("_") && typeof v[name] === "function",
);
const rows = functions.map((name) => {
    const alias = name.endsWith("_") ? name.slice(0, -1) : name;
    const async = alias.endsWith("Async");
    const base = async ? alias.slice(0, -5) : alias;
    const native = snake(base);
    let equivalents = aliases[base] ?? [ `valibro.${native}`, `valibro.json.${native}` ].filter(
                                           (n) => symbols.has(n));
    if (base === "ValiError")
        equivalents = [ "types.ValidationError" ];
    let status = equivalents.length ? "available_native" : "missing";
    let notes = profiles[base] ??
                "Native V API; see docs/compatibility.md for shared language differences.";
    if (async)
        notes =
            "Native callbacks can perform I/O directly; use safe_parse_async, parser_async, parse_async, or Future.await to schedule/await execution. " +
            notes;
    if (base.startsWith("setGlobal") || base.startsWith("getGlobal") ||
        base.startsWith("deleteGlobal") || base.includes("SchemaMessage") ||
        base.includes("SpecificMessage"))
        notes =
            "Explicit Context owns configuration and language-specific messages; no process-global mutable state.";
    if (profiles[base])
        status = "documented_profile";
    return {
        valibot : name,
        status,
        equivalents,
        notes,
        ...(evidence[base] ? {evidence : evidence[base]} : {}),
    };
});
const data = {
    upstream : {
        package : "valibot",
        version : JSON.parse(fs.readFileSync(path.join(upstream, "library/package.json"))).version,
        revision : cp.execFileSync("git", [ "-C", upstream, "rev-parse", "HEAD" ], {
                         encoding : "utf8"
                     }).trim(),
    },
    scope :
        "Public runtime functions, including aliases. Internal underscore helpers, TS-only types, JS regex instances, and ecosystem packages are not native V API functions.",
    meaning : "Availability and documented profiles do not establish exhaustive functional parity.",
    counts : {
        total : rows.length,
        available_native : rows.filter((r) => r.status === "available_native").length,
        documented_profile : rows.filter((r) => r.status === "documented_profile").length,
        missing : rows.filter((r) => r.status === "missing").length,
    },
    functions : rows,
};
fs.writeFileSync(path.join(root, "docs/capabilities.json"), JSON.stringify(data, null, 2) + "\n");
const missing = rows.filter((r) => r.status === "missing");
console.log(JSON.stringify(data.counts));
if (missing.length) {
    console.error("Unmapped functions: " + missing.map((r) => r.valibot).join(", "));
    process.exitCode = 1;
}
