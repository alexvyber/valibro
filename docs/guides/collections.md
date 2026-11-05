# Collections

Collection schemas validate entries in order and preserve structured issue paths. On failure, typed `.output` is absent and boxed `.raw_output` can retain partial results.

## Arrays and maps

`array` applies an item schema. `record` validates string-keyed maps; `map_schema` supports native hashable key types. Key and value schemas can transform their inputs.

```v
import valibro as v

array := v.array(v.pipe_to(v.string(), v.to_number()))
assert v.parse(array, ['1', '2'])! == [1.0, 2.0]
assert !v.safe_parse(array, ['1', 'bad']).success
record := v.record(v.string(), v.pipe(v.number_of[int](), v.min_value(0)))
assert v.safe_parse(record, {'age': 42}).success
assert !v.safe_parse(record, {'age': -1}).success
```

Use `length_of[T]` for sequence length, `entries[T]` for map entries or declared struct fields, and `size[T]` for countable values. Each has minimum, maximum, and exclusion forms. `mime_type` validates blob/file MIME metadata.

## Item callbacks

Map, filter, find, reduce, sort, every, some, and check actions receive native callbacks. Index-aware callbacks use the original input indices; `_with_array` variants also receive the original input array. Use `pipe_to` for actions that change the result type, such as mapping or reducing.

```v
import valibro as v

schema := v.pipe_to(v.array(v.number_of[int]()), v.map_items(fn (value int, index int) int {
    return value + index
}))
assert v.parse(schema, [10, 10, 10])! == [10, 11, 12]
filtered := v.pipe(v.array(v.number_of[int]()), v.filter_items(fn (value int, index int) bool {
    return value > 0
}))
assert v.parse(filtered, [-1, 2, 0, 3])! == [2, 3]
```

## Ordered sets

`types.new_set` deduplicates values while retaining insertion order. Floating sets use SameValueZero, including NaN equality, and normalize signed zero. `new_set_with` and `set_with` accept explicit equality callbacks.

```v
import valibro as v
import valibro.types

input := types.new_set(['a', 'a', 'b'])
assert input.values == ['a', 'b']
schema := v.set(v.pipe(v.string(), v.to_upper_case()))
assert v.parse(schema, input)!.values == ['A', 'B']
```

## Custom-key entry maps

`types.entry_map` and the `entry_map` schema support keys that native hash maps cannot represent. Supply equality explicitly. Collisions preserve the first key position and the last value. The schema's equality callback governs transformed output keys.

```v
import valibro as v
import valibro.types

input := types.entry_map([types.MapEntry[string, int]{key: 'a', value: 1},
    types.MapEntry[string, int]{key: 'a', value: 2}], fn (a string, b string) bool {
    return a == b
})
schema := v.entry_map(v.string(), v.number_of[int](), fn (a string, b string) bool {
    return a == b
})
output := v.parse(schema, input)!
assert output.entries.len == 1
assert output.entries[0].value == 2
```

Browse [root collection APIs](/api/) and [native container types](/api/types/).
