# Composition and execution

Import `valibro as v`. Native contracts live in `valibro.types`:
`Schema[I, O]`, `Action[T]`, `Transformation[I, O]`, `Dataset[T]`, `Issue`,
`Maybe[T]`, `Set[T]`, `Function[I, O]`, and `Future[T]`.

## Collections

`array(item)` validates/transforms arrays. `record(key, value)` handles native
string-keyed maps; `map_schema(key, value)` supports native hashable key types.
`set(item)` operates on insertion-ordered `types.Set[T]`, constructed with
`types.new_set(values)` and inspected through `.values`. Float sets use
SameValueZero and normalize signed zero; other values use native equality.
`entry_map(key_schema, value_schema, output_equal)` validates
`types.EntryMap[K, V]`, whose ordered `.entries` contain `types.MapEntry[K, V]`.
Construct it with `types.entry_map(entries, input_equal)` for arbitrary keys,
including structs or explicit object identity tokens. Collisions keep the first
key position and last value. `set_with(item, output_equal)` and
`types.new_set_with(values, input_equal)` similarly choose set equality.
Boxed partial outputs retain the same native equality as typed outputs, including
all numeric widths and comparable structs, arrays, maps and aliases. Default
float sets use SameValueZero (NaN equals NaN) and normalize signed zero even after
a failed transformation. Raw map collisions keep the first key position and last
value. Explicit comparators also govern valid output values in mixed raw views;
failed original inputs retain their own native type and equality.

`length_of[T]` and its min/max/not variants measure collection length.
`entries[T]` and its min/max/not variants count map entries or declared struct
fields. `size[T]` and its min/max/not variants measure countable collections,
blobs, and files. `mime_type` checks blob/file MIME metadata.

Array actions include `map_items`, `filter_items`, `find_item`, `reduce_items`,
`every_item`, `some_item`, `check_items`, `includes_item`, `excludes_item`, and
`sort_items`. Callbacks receive item/index; reduce also receives its accumulator.
`_with_array` variants of map/filter/find/reduce/every/some/check additionally
receive the original array, matching upstream's callback capabilities. Predicates
short-circuit where appropriate; `check_items` reports each failing index.
`find_item` returns `Maybe[T]`, with `.undefined` for no match. Sort is stable.

## Native structs and alternatives

`field` supplies a name, getter, setter, and child schema. `object` validates a
native struct using those fields; `object_from` supplies an output initializer
for different input/output struct types. Native struct layouts stay fixed.
JSON schemas provide dynamic strip/preserve/reject/rest policies instead.

`literal`, `picklist`, `enum_schema`, `custom`, `unknown`, `any_value`, `never`,
`union`, `lazy`, and `lazy_with` retain explicit native input/output types.
Native unions require compatible branch signatures. Lazy-with callbacks can
select a schema from the current input. JSON intersections and discriminated
unions support heterogeneous structural branches.

Native unions return the first successful branch. If only one failing candidate
remains after preferring typed branches, its partial output is retained. With
multiple failing candidates, the union reports nested issues and retains its
original input in `.raw_output`, including when branches change the native type.
Skipped transformations preserve that raw value; fallbacks replace it with their
successful output. Arrays, maps, and sets retain the same distinction for their
partial children.

```v
import valibro as v
import valibro.types

positive := v.pipe(v.pipe_to(v.string(), v.to_number()), v.gt_value(0.0))
negative := v.pipe(v.pipe_to(v.string(), v.to_number()), v.lt_value(0.0))
result := v.safe_parse(v.union([positive, negative]), '0')
assert !result.success
assert types.value_as[string](result.raw_output) or { panic(err) } == '0'
```

## Presence, defaults, and fallback

`Maybe[T]` distinguishes `.missing`, `.undefined`, `.null`, and `.value`.
Construct values with `types.missing`, `undefined_value`, `null_value`, and `some`.

- `optional` accepts missing/undefined; `exact_optional` accepts missing only.
- `nullable` accepts null; `nullish` accepts all absent states.
- `undefinedable` accepts explicit undefined.
- `non_optional`, `non_nullable`, and `non_nullish` reject their indicated states
  before and after wrapped parsing. They accept optional error messages.

Optional/nullable/nullish/undefinedable factories accept a static default.
`_with_default` variants compute a default from Config when needed.
`get_default` returns the static/computed native default as a V option.
`_with_default_context` variants additionally receive an optional input dataset;
`get_default_with_context` supplies an introspection dataset explicitly. Ordinary
introspection passes none; parsing supplies the current Maybe input before child
validation. Computed defaults are validated/transformed by the child schema.
`_with_default_state` variants receive the same contextual arguments and return
`Maybe[I]`, allowing computed null/undefined as well as present values.
Native and JSON `unwrap` return the original stored wrapped schema, including its
metadata and checks, and discard outer pipeline/fallback behavior. For wrappers
whose inner type still contains Maybe, use fallible `unwrap_as[I, O, P, Q]` with
the exact inner input/output types. JSON recursive default/fallback getters preserve object/tuple
shape and project values unavailable in JSON to null.

`fallback(schema, value)` recovers validation failures. `fallback_fn` supplies
original input and issues to a native callback. `fallback_with_context` supplies
an optional failed output dataset and Config, including resolved issues and
partial transformed output. `get_fallback(schema, config?)` invokes that provider
without a dataset; `get_fallback_with_context` supplies a dataset explicitly.
Providers receive none during ordinary introspection. Runtime exceptions propagate.

## Runtime JSON schemas

```v
import valibro.json as j
import valibro as v
import x.json2

schema := j.object({
    'name': j.from_schema(v.pipe(v.string(), v.trim(), v.min_length(2)))
    'age': j.optional(j.number(), json2.Any(18))
})
input := json2.decode[json2.Any]('{"name":"  Alex  "}') or { panic(err) }
output := j.parse(schema, input) or { panic(err) }
```

`object` strips unknown keys; `loose_object` preserves them; `strict_object`
rejects the first unknown key; `object_with_rest` validates extras.
`tuple`, `loose_tuple`, `strict_tuple`, and `tuple_with_rest` provide the analogous
array policies. `record` validates keys and values. Record/rest traversal retains
`__proto__`, `prototype`, and `constructor` as ordinary keys. Map iteration order
is retained; numeric-looking keys are not reordered.

`union_schema`, `intersect`, `variant`, and lazy schemas compose recursively.
`variant` supports nested discriminators and reports invalid-discriminator
expectations. Intersections evaluate branches before merging typed outputs.

`pick`/`omit` select object fields. `partial`/`required` accept an optional key
list: omitted means all keys, an empty list means none. Shape operations retain
annotations, messages, typed examples and existing pipeline/fallback closures.
As in Valibot, reshaping a piped/fallback schema updates exposed entries while the
existing wrapper closure still executes its original wrapped schema.
`required_with_message(schema, message, keys...)` supplies the required-entry
message; object factories and non-presence factories also accept messages. `keyof` builds a key picklist.
`entries_from_list` and `entries_from_objects` build/merge entry maps.

`from_schema` adapts native string/bool/f64/JSON inputs with runtime type checks;
JSON-native outputs and typed examples are retained. `native` exposes a JSON
schema through the typed core. `j.pipe` accepts actions on `json2.Any`;
`j.partial_check` supports cross-field checks, including `$` wildcard array
paths. It can run on an untyped dataset when the selected paths remain valid;
empty selections follow upstream readiness semantics.

## JSON callbacks

`parse_json_with_config(ParseJsonConfig{reviver: ...})` returns
`Transformation[string, Maybe[json2.Any]]`. The reviver receives key, parsed
value, and `JsonReviverContext`; `.source` contains the original primitive token.
`.holder` is a snapshot of the containing object/array, including previous sibling replacements.
Callbacks run in postorder, including the root key `''`. Return `types.some(value)`
to retain/replace, or an absent Maybe to remove a value. Root removal returns
undefined; array removal projects an absent element to native JSON null.
Duplicate keys retain their final value/source. Thrown V callback errors become
JSON transformation issues, following upstream's catch behavior.

`stringify_json_with_config(StringifyJsonConfig{...})` accepts JSON values.
`replacer` runs in preorder, including the root. `replacer_with_context` also
receives `JsonReplacerContext.holder` and takes precedence over `replacer`.

`replacer_with_presence` takes highest precedence and receives
`(key string, value types.Maybe[json2.Any], context JsonReplacerContext)`.
Its input distinguishes `.undefined`, `.null`, and `.value`, so it can recover an
undefined root or a property omitted by a toJSON hook. Missing hook results project
to undefined. Return a present value to replace it, `.null` to emit null, or an
absent Maybe to omit an object property, emit an array null, or fail at the root.
Legacy JSON-only replacers continue to skip undefined values. Holder snapshots
remain JSON projections; inspect the callback input state for undefined presence.

```v
import valibro as v
import valibro.types
import x.json2

config := v.StringifyJsonConfig{
    replacer_with_presence: fn (key string, value types.Maybe[json2.Any], context v.JsonReplacerContext) !types.Maybe[json2.Any] {
        if value.state == .undefined {
            return types.some(json2.Any('unavailable'))
        }
        return value
    }
}
schema := v.pipe_to(v.unknown[types.Undefined](),
    v.stringify_json_value_with_config[types.Undefined](config))
assert v.parse(schema, types.Undefined{}) or { panic(err) } == '"unavailable"'
```

Callbacks run after the visited value's toJSON hook. Hook failures stop before
its replacer; replacer failures become transformation issues. `property_list`
selects/orders object keys: none means ordinary keys; an empty list selects none.
`space` accepts an integer width or literal string, without clipping to ten.
Float indentation is removed. Serialization is iterative; `max_depth: 0` means
no explicit depth guard. `stringify_json_with_config_utf16` is an explicit unit
output API; ordinary output remains valid UTF-8. V callback errors become issues.

Both parse and stringify configs accept `binary64_numbers: true` to round native
integer JSON values to binary64. Parsing retains original reviver source
text. The default retains native integer alternatives when supplied by the decoder.
The tested `x.json2` decoder can select `f64` for integer tokens, so large JSON
integer text is not guaranteed to retain precision. Explicit native integer
values retain precision when serialized without binary64 projection.

Default `stringify_json_value[T]` handles native/JSON scalars, arrays, and maps:
floats use native compact formatting, nonfinite numbers become null, signed zero
is retained, unsupported map values are omitted, and unsupported array values
become null. BigInt requires an explicit JSON conversion. Dates emit ISO strings with native
precision, or null when invalid. Set, EntryMap, Blob and File serialize native
struct fields. Function values fail; await Futures before serialization.
See [native behavior and migration](native_behavior.md).
`stringify_json_value_with_config[T](config, message?)` adds configuration.

Implement `jsoncodec.JsonValueProvider` with
`pub fn (value T) to_json_value(key string) !types.Maybe[json2.Any]` for native
toJSON behavior. It receives the actual root/property/index key when traversed,
immediately before that property's replacer. Omitted/replaced parent objects and
property whitelists skip unvisited hooks. If a replacer edits a parent object or
array, unchanged child projections at the same key/index retain their deferred
hooks. Reconciliation also follows unchanged descendant paths through edited
containers. Removed or changed leaf values discard the original hooks; newly added
JSON values serialize normally. This follows native JSON value semantics, so
rearranging identical opaque provider projections does not transfer JS identities.
Errors become transformation issues.
Native providers are opaque empty objects in parent holder snapshots until their
hook runs; the JSON callback API does not expose arbitrary native object fields.
Ordinary native structs are traversed recursively, so providers on nested fields
run just as they do in arrays/maps. Field tags retain V conventions:
`@[json: 'name']` renames, `@[skip]`/`@[json: '-']` skips without invoking hooks,
and `@[omitempty]` omits empty fields. Absent options are omitted unless marked
`@[json_null]` or `@[required]`, which emit null. Embedded fields are flattened;
collisions with outer keys use V's embedded-type prefix. Fixed arrays and
non-nil pointers are traversed; nil pointer fields are omitted. A whole-object
JsonValueProvider or V custom JSON encoder takes precedence over field traversal.
Nil pointers at the root, in arrays, or in maps emit null (and can be recovered
by a presence-aware replacer) without calling provider/encoder methods. Nil pointer
struct fields follow V omission rules. Non-nil pointers traverse their values;
failed root serialization retains the original pointer in `.raw_output`.
Struct graphs must be acyclic; holder snapshots and opaque provider projections
retain the native JSON value model.
See [compatibility](compatibility.md) for holder/prototype and UTF-16 boundaries.

Native conversions also accept Maybe states transparently; see the
[primitive conversion table](primitive_api.md#dates-and-conversions).

Native `Maybe[T]` values serialize their semantic value, without exposing internal
`state` or `value` fields. Nested wrappers unwrap recursively, including hooks,
Date values and collection payloads:

| Maybe state | Root | Array slot | Object/map/struct entry |
| --- | --- | --- | --- |
| `.missing` | Undefined; fails unless recovered | Undefined; null unless replaced | Entry absent; no callback for that key |
| `.undefined` | Undefined; fails unless recovered | Undefined; null unless replaced | Present undefined; omitted unless replaced |
| `.null` | JSON null | JSON null | JSON null |
| `.value` | Serialize the contained value | Serialize the contained value | Serialize the contained value |

`replacer_with_presence` can recover undefined roots/slots/entries. A Maybe returned
by a reviver, replacer or toJSON provider follows that callback's return contract;
missing/undefined there mean deletion/omission. This differs from an input
`Maybe.missing` entry, which is absent before traversal. V `?T` options keep their
existing field-tag/null conventions. BigInt still needs an explicit conversion to
a JSON value; JSON-valued replacer callbacks do not carry BigInt values.

Parse and stringify transformations can now compose directly through their native
Maybe output:

```v
import valibro as v
import valibro.types
import x.json2

schema := v.pipe_to(
    v.pipe_to(v.string(), v.parse_json_with_config(v.ParseJsonConfig{})),
    v.stringify_json_value[types.Maybe[json2.Any]]())
assert v.parse(schema, '{"a":1}') or { panic(err) } == '{"a":1}'
```

A `time.Time` held in `json2.Any` is a native Date value. Its JSON conversion runs
before its replacer: valid dates supply an ISO string with native precision, invalid dates
supply null. If a toJSON provider or replacer returns a Date object, that returned
object does not run toJSON again at the same position; it serializes as an empty
object. Dates at newly visited descendant positions run their normal conversion.

## Pipelines, errors, and configuration

Consecutive validations collect issues. A transformation boundary after an issue
marks the dataset untyped and stops work. `abort_pipe_early` skips later pipe
validations; `abort_early` also stops collection traversal before inserting the
failing entry into partial output. Metadata actions do not execute validation.

`raw_check_with_context`, `raw_transform_with_context`, and
`raw_transform_to_with_context` receive the current Dataset and Config. Raw checks
can observe untyped datasets. `types.run`, `run_action`, and `run_transformation`
execute hooks with resolved messages; direct `.run` fields are extension hooks.

Issues contain `kind`, `code`, `message`, `expected`, `received`, language/abort
metadata, key/index `path` with native `path_types`, exact boxed `path_keys`,
and recursive alternative `issues`. Empty expected
strings represent upstream null. UTF-16 getters encode the native strings on demand; no unit arrays are stored.
`forward` appends only existing map keys/integer array indexes to new issue paths,
stopping at the deepest existing prefix. Missing paths do not throw, and scalar
truthiness is irrelevant. Arrays/strings have no simulated properties.
`flatten` groups root/nested/other messages; set or unsupported native map keys
have no dot path. Native set diagnostics retain ordinal paths with
`dot_path_unavailable`; `path_present` distinguishes absent and explicit empty
paths. `get_dot_path` returns an empty string when unavailable. `summarize`
renders messages with available paths; `is_vali_error` checks validation errors.

`safe_parse` has absent `.output` on validation failure; `.typed` exposes dataset
state. `.raw_output` always contains the actual output in `types.NativeValue`.
Use `types.value_is[T](raw)` and fallible `types.value_as[T](raw)` to inspect it.
Failed type-changing transformations preserve their original input; a failed Date
conversion uses `types.InvalidDate`. A conversion that produced NaN retains NaN.

Mixed partial collections use `types.RawArray`/`RawSet` (`.items`),
`RawMap`/`RawObject` (`.entries` of boxed keys and values), and `RawStruct[T]`
(`.value` typed snapshot, `.keys` retained fields, `.fields` boxed overrides).
Children may themselves be raw views. This preserves heterogeneous failure output
without pretending it is a valid `O`. `Dataset.raw_value` exposes the optional
same override to advanced callbacks; `types.run` retains the typed snapshot too.
Struct fields retain a child's raw override even when its `.typed` flag is true:
a typed aggregate union failure can still carry the original input with a
different native type. Nested `RawStruct` overrides preserve that value at every
field level. Inspect the raw view for failure output; the statically typed
snapshot is not a successful result. Nested type-changing struct schemas use the
same field, message, and abort rules as their scalar and collection children.
`parse` and `safe_parse_checked` return runtime exceptions as V errors;
nonfallible `safe_parse` panics. Fallbacks/cache/futures preserve exception identity
within the native error model.

A `Context` owns scoped global/specific/schema message tables and configuration.
Message precedence is factory, specific, schema-only, parse/config, then global.
Callbacks receive resolved issue fields and Config metadata once per issue.
Context updates replace/clone maps. `config(schema, settings)` binds settings.

## Functions, workers, caching, and metadata

`function_schema[I, O]` validates `types.Function` wrappers. `args` validates a
packed native argument; `returns` validates output; `returns_checked` composes
after argument validation. Created wrappers capture configuration. Calls return
`!O`; multiple native arguments can be packed into a struct.

`promise[T]` and `await_future[T]` handle Future values. `safe_parse_async` and
`safe_parser_async` return buffered channels; `parse_async` and `parser_async`
return Futures. Future copies/repeated awaits share one cached resolution.
Native callbacks can perform I/O directly, replacing separate JS Promise APIs.

`cache(schema, key_function, capacity)` provides synchronized bounded LRU storage.
`cache_with_config` selects max size, max age, and injectable clock. `cached`
exposes schema/key/get/set/clear. Expiry is strictly after the age bound; capacity
zero disables storage. Failures are cached; exceptions are not. Configuration
contributes to keys. `v.message_fn` and `types.identified_message` attach a stable
identity: copies share cache entries and separately identified callbacks do not.
Only bare unidentified function callbacks bypass caching. Callers choose input identity and
must avoid mutating reference-bearing cached outputs.

String metadata helpers remain available. Use `_for[T]` title/description/
metadata/examples factories and `get_examples_for` for other output types.
Metadata maps merge by key; later annotations override named values.
`brand_for[T, B]`/`flavor_for[T, B]` use marker wrappers; readonly follows V's
immutability model. Native symbols/instances use marker identity/static types,
with no JavaScript prototype chain.
