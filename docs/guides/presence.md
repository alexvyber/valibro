# Presence and defaults

Use native V options for optional typed values. Unwrap them before validating, and select defaults with an `or` block. Defaults supplied this way go through the same validation and transformation as other inputs.

```v
import valibro as v
import valibro.types

schema := v.pipe(v.string(), v.trim(), v.min_length(2))
name := ?string(' Alex ')
if value := name { assert v.parse(schema, value)! == 'Alex' }
missing := ?string(none)
assert v.parse(schema, missing or { 'guest' })! == 'guest'
```

V 0.5.2 cannot instantiate `Schema[?I, ?O]`. The library therefore does not introduce an option-container substitute. Native structs may hold options, and application code controls whether absence is accepted, defaulted, or rejected.

## JSON fields

JSON objects distinguish an absent key, explicit null, and a value. `optional` accepts a missing field; `nullable` accepts null. Compose the policies when both are allowed. FieldConfig selects an optional literal default; it does not accept multiple positional defaults or synthetic undefined values.

```v
import valibro.json as j
import x.json2

schema := j.object({
    'name': j.optional(j.string(), default_value: json2.Any('guest'))
    'note': j.optional(j.nullable(j.string()))
})
output := j.parse_text(schema, '{"note":null}')!.as_map()
assert output['name']! == json2.Any('guest')
assert output['note']! is json2.Null
assert !j.is_valid(schema, json2.Any({'name':json2.Any(json2.Null{})}))!
```

## Validation fallback

A fallback replaces an ordinary validation rejection with an output value. It does not rerun the replacement through the schema, and it does not swallow execution errors.

```v
import valibro as v
import valibro.types

schema := v.fallback(v.pipe(v.string(), v.min_length(3)), 'anonymous')
assert v.parse(schema, 'x')! == 'anonymous'
computed := v.fallback_fn(v.pipe(v.string(), v.min_length(3)), fn (input string, issues []types.Issue) string {
    return 'guest'
})
assert v.parse(computed, 'x')! == 'guest'
```
