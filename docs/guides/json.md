# Runtime JSON schemas

Import `valibro.json` for unknown JSON values and heterogeneous structures. Its `Schema` accepts `x.json2.Any`; use native typed schemas when the V input type is already known.

## Objects and adapters

`from_schema` adapts a typed schema to runtime JSON. `native` adapts a runtime schema to the typed pipeline machinery. `parse_text` parses JSON text then validates it; `parse` and `safe_parse` operate on an existing JSON value.

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
assert !j.safe_parse(schema, 'wrong type').success
```

Ordinary objects strip unknown entries. `strict_object` rejects them, `loose_object` retains them, and `object_with_rest` validates them through a rest schema. `record` validates arbitrary string keys and values.

## Shape operations and defaults

`pick` and `omit` select fields. `partial` makes selected/all fields optional; `required` reverses that policy, with `required_with_message` for a diagnostic. `keyof` builds a key picklist. Object entries are explicit maps and can be assembled with `entries_from_list` or `entries_from_objects`.

```v
import valibro.json as j
import x.json2

base := j.object({'name': j.string(), 'age': j.number()})
partial := j.partial(base)
assert j.safe_parse(partial, map[string]json2.Any{}).success
picked := j.pick(base, ['name'])
assert j.parse_text(picked, '{"name":"Alex"}')!.as_map().len == 1
strict := j.strict_object({'name': j.string()})
extra := json2.Any({'name': json2.Any('Alex'), 'extra': json2.Any(true)})
assert !j.safe_parse(strict, extra).success
```

Presence wrappers, literal defaults, computed defaults, fallbacks, and recursive default/fallback extraction are available for JSON schemas. Missing properties differ from explicit null values.

## Tuples and alternatives

`array` applies one item schema. `tuple` validates positional schemas; `strict_tuple` rejects extra items, `loose_tuple` preserves them, and `tuple_with_rest` validates additional items. `union` chooses an alternative, `intersect` combines compatible outputs, and `variant` selects by a discriminator. `lazy` and `lazy_with` defer schema selection.

```v
import valibro.json as j
import x.json2

tuple := j.strict_tuple([j.string(), j.number()])
assert j.safe_parse(tuple, json2.Any([json2.Any('Alex'), json2.Any(42)])).success
alternative := j.union([j.string(), j.number()])
assert j.safe_parse(alternative, 42).success
assert !j.safe_parse(alternative, true).success
variant := j.variant('kind', [j.object({'kind': j.literal('text'), 'value': j.string()}),
    j.object({'kind': j.literal('count'), 'value': j.number()})])
assert j.parse_text(variant, '{"kind":"count","value":42}')!.as_map().len == 2
```

Runtime JSON errors use the same structured issues and partial-output model. See [JSON module reference](/api/json/), [JSON configuration](/guides/json-config/), and [presence](/guides/presence/).
