# Transformations

A same-type action goes into `pipe`. A `Transformation[I, O]` that changes the type goes into `pipe_to`. Validation issues stop a later transformation from running.

## Text transformations

Trimming, case conversion, case-style conversion, and Unicode normalization are explicit. Use `to_string_from[T]` for an actual conversion; a string needs no identity conversion.

```v
import valibro as v

schema := v.pipe(v.string(), v.trim_start(), v.trim_end(), v.to_lower_case(), v.to_kebab_case())
assert v.parse(schema, '  Hello World  ')! == 'hello-world'
converted := v.pipe_to(v.number_of[int](), v.to_string_from[int]())
assert v.parse(converted, 42)! == '42'
```

## Native conversions

`to_number`, `to_bigint`, `to_boolean`, and `to_date` take strings. `_from[T]` variants accept explicitly typed inputs. Arrays and maps do not implicitly become numbers or dates. Native boolean conversion and validated boolean parsing are distinct: `parse_boolean` rejects unrecognized spellings.

```v
import valibro as v

number := v.pipe_to(v.string(), v.to_number())
assert v.parse(number, '42.5')! == 42.5
boolean := v.pipe_to(v.string(), v.parse_boolean())
assert v.parse(boolean, 'true')! == true
assert !v.is_valid(boolean, 'perhaps')!
```

## Custom transformations

`transform` preserves the type; `transform_to` changes it. `raw_transform`, `raw_transform_to`, and their context variants return a dataset, allowing an explicit issue or runtime exception. Keep callbacks deterministic when using a cache.

```v
import valibro as v

schema := v.pipe_to(v.string(), v.transform_to(fn (text string) int {
    return text.runes().len
}))
assert v.parse(schema, '世界')! == 2
```

## Conversion providers

Native types can implement `NumberProvider`, `BigintProvider`, `BooleanProvider`, `DateProvider`, or `StringProvider`. Each returns the target native value as a fallible result, without an intermediate JavaScript primitive protocol.

```v
import valibro as v

struct Amount {
    value f64
}

pub fn (amount Amount) to_number() !f64 {
    return amount.value
}

fn main() {
    schema := v.pipe_to(v.schema[Amount](), v.to_number_from[Amount]())
    assert v.parse(schema, Amount{value: 42.5})! == 42.5
}
```

See [JSON parsing and serialization](/guides/json-config/) for JSON transformations and [types](/api/types/) for provider declarations.

## Native fallible callbacks

Try_transform composes a native fn (I) !O. Its errors propagate, including through is_valid and fallback wrappers.

```v
import valibro as v

schema := v.pipe_to(v.string(), v.try_transform[string, int](fn (text string) !int {
    if text == '' { return error('Empty input') }
    return text.len
}))
assert v.parse(schema, 'Alex')! == 4
if _ := v.is_valid(schema, '') { assert false } else { assert err.msg() == 'Empty input' }
```
