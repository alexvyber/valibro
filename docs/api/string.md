# string

Creates a schema for native, well-formed UTF-8 strings. Input and output are both `string`.

## Signature

```v signature
fn string(messages ...types.ErrorMessage) types.Schema[string, string]
```

Call it as `v.string()` through the root module. `types` refers to `valibro.types`.

## Example

```v
import valibro as v

schema := v.string()
result := v.inspect(schema, 'Hello, 世界')!
assert (result.issues.len == 0 && result.typed)
assert result.typed
assert result.value == 'Hello, 世界'
assert v.is_valid(schema, '')!
```


## Parameters

- `messages`: zero or one custom error message. Omit it to use `Expected a valid UTF-8 string`. Passing more than one triggers an assertion.

## Returns

A reusable `types.Schema[string, string]`. Valid input is returned unchanged. The schema permits empty strings; add an action to impose length or content requirements.


## Validation failures

Malformed UTF-8 produces a schema issue with code `string`. Parse returns a ValidationError. Inspection has typed == false and retains the original bytes in value.

```v
import valibro as v

schema := v.string('Use valid UTF-8')
input := [u8(0xff)].bytestr()
result := v.inspect(schema, input)!
assert !(result.issues.len == 0 && result.typed)
assert !result.typed
assert result.issues[0].code == 'string'
assert result.issues[0].message == 'Use valid UTF-8'
assert result.issues.len > 0
```

## Native behavior

This is a statically typed schema. Non-string input is rejected by the V compiler. It does not stringify values, trim whitespace, or normalize Unicode.

Use `min_code_points` to count Unicode code points, `min_bytes` to count UTF-8 bytes, or grapheme actions for user-perceived character boundaries. The plain `min_length` string action counts code points in the native V profile.

## Related

- [pipe](/api/pipe/): attach string checks and transformations.
- [parse](/api/parse/): inspect validation output.
- [Quick start](/guides/quick-start/): compose a username schema.
