# Runtime JSON schemas

Import `valibro.json` for unknown JSON values and heterogeneous structures. Its `Schema` accepts `x.json2.Any`; use native typed schemas when the V input type is already known.

## Objects and adapters

`from_schema` adapts a typed schema to runtime JSON. `native` adapts a runtime schema to the typed pipeline machinery. `parse_text` decodes with `jsoncodec.decode`, preserving exact ties-to-even float rounding, then validates the value. `parse` and `inspect` operate on an existing JSON value.

```v
import valibro as v
import valibro.json as j

schema := j.object({
    'name': j.from_schema(v.pipe(v.string(), v.trim(), v.min_length(2)))
    'age': j.from_schema(v.pipe(v.number(), v.integer(), v.min_value(0.0)))
})
output := j.parse_text(schema, '{"name":" Alex ","age":42}')!
object := output.as_map()
assert (object['name'] or { panic('name') }).str() == 'Alex'
assert !j.is_valid(schema, 'wrong type')!
```

Ordinary objects strip unknown entries. `strict_object` rejects them, `loose_object` retains them, and `object_with_rest` validates them through a rest schema. `record` validates arbitrary string keys and values.

All object modes, records, and discriminated variants require a JSON object. Arrays, including empty arrays, fail at the object boundary; they are never converted to objects with numeric keys. An object property named `"0"` remains an ordinary string key.

```v
import valibro.json as j
import x.json2

schema := j.object({'0': j.string()})
assert !j.is_valid(schema, json2.Any([json2.Any('Alex')]))!
assert j.parse_text(schema, '{"0":"Alex"}')!.as_map().len == 1
```

## Numeric precision and equality

`equal`, literal/picklist schemas, and native membership checks preserve supplied JSON integer values without converting them to floats. Signed and unsigned integers compare by their exact value. A mixed integer/float pair compares equal only when the float represents that integer exactly; for example, integer 42 equals float 42.0, while integer 9007199254740993 differs from float 9007199254740992.0. These rules also apply inside recursive JSON equality and intersection output merging.

```v
import math
import valibro.json as j
import valibro.types
import x.json2

left := json2.Any(i64(9007199254740992))
right := json2.Any(i64(9007199254740993))
assert !j.equal(left, right)
assert !j.is_valid(j.literal(left), right)!
assert types.new_set([left, right]).values.len == 2
assert j.equal(json2.Any(42), json2.Any(42.0))
rounded := j.parse_text(j.number(), '1e23')!
assert math.f64_bits(rounded.f64()) == u64(4950912855330343670)
```

Signed zeros compare equal. For supplied nonfinite V values, recursive JSON `equal` keeps NaN unequal, while native membership/set checks treat NaNs as equal. Equal-sign infinities compare equal; an infinity never equals an integer. NaN and Infinity are not accepted as JSON text tokens.

Float decoding rounds once to binary64, including halfway values and subnormals. Dynamic integer-token representation still follows `x.json2`, which can select `f64`; exact comparison cannot recover digits lost during decoding or an explicit `j.number()` conversion to `f64`. For exact large integers arriving as text, use strings plus BigInt conversion or an explicitly typed integer decoder. See [JSON configuration](/guides/json-config/).

## Shape operations and defaults

`pick` and `omit` select fields. `partial` makes selected/all fields optional; `required` reverses that policy, with `required_with_message` for a diagnostic. `keyof` builds a key picklist. Object entries are explicit maps and can be assembled with `entries_from_list` or `entries_from_objects`.

```v
import valibro.json as j
import x.json2

base := j.object({'name': j.string(), 'age': j.number()})
partial := j.partial(base)
assert j.is_valid(partial, map[string]json2.Any{})!
picked := j.pick(base, ['name'])
assert j.parse_text(picked, '{"name":"Alex"}')!.as_map().len == 1
strict := j.strict_object({'name': j.string()})
extra := json2.Any({'name': json2.Any('Alex'), 'extra': json2.Any(true)})
assert !j.is_valid(strict, extra)!
```

Missing fields use optional; explicit null uses nullable. See [presence](/guides/presence/).

## Tuples and alternatives

`array` applies one item schema. `tuple` validates positional schemas; `strict_tuple` rejects extra items, `loose_tuple` preserves them, and `tuple_with_rest` validates additional items. `union` chooses an alternative, `intersect` combines compatible outputs, and `variant` selects by a discriminator. `lazy` and `lazy_with` defer schema selection.

```v
import valibro.json as j
import x.json2

tuple := j.strict_tuple([j.string(), j.number()])
assert j.is_valid(tuple, json2.Any([json2.Any('Alex'), json2.Any(42)]))!
alternative := j.union([j.string(), j.number()])
assert j.is_valid(alternative, 42)!
assert !j.is_valid(alternative, true)!
variant := j.variant('kind', [j.object({'kind': j.literal('text'), 'value': j.string()}),
    j.object({'kind': j.literal('count'), 'value': j.number()})])
assert j.parse_text(variant, '{"kind":"count","value":42}')!.as_map().len == 2
```

Runtime JSON errors use the same structured issues and partial-output model. See [JSON module reference](/api/json/), [JSON configuration](/guides/json-config/), and [presence](/guides/presence/).
