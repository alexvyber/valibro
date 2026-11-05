# Collections

Collection schemas validate entries in order and preserve structured issue paths. Parse returns an error on failure; inspect can expose partial values through raw_value.

## Arrays and maps

`array` applies an item schema. `record` validates string-keyed maps; `map_schema` supports native hashable key types. Key and value schemas can transform their inputs.

```v
import valibro as v

array := v.array(v.pipe_to(v.string(), v.to_number()))
assert v.parse(array, ['1', '2'])! == [1.0, 2.0]
assert !v.is_valid(array, ['1', 'bad'])!
record := v.record(v.string(), v.pipe(v.number_of[int](), v.min_value(0)))
assert v.is_valid(record, {'age': 42})!
assert !v.is_valid(record, {'age': -1})!
```

Use `length_of[T]` and its min/max/not variants for native collection counts. mime_type validates MIME metadata; it does not inspect the bytes.

## Item validation and transformations

Check_items collects an indexed issue for every failing element. Every_item and some_item provide aggregate checks. Use ordinary V array mapping, filtering, loops and sorting inside a native transformation when needed.

```v
import valibro as v

schema := v.pipe(v.array(v.number_of[int]()), v.min_length_of[[]int](1),
    v.check_items(fn (value int, index int) bool { return value > 0 }))
issues := v.inspect(schema, [1, -1])!.issues
assert issues.len == 1
assert v.get_dot_path(issues[0]) == '1'
changed := v.pipe(v.array(v.number_of[int]()), v.transform[[]int](fn (input []int) []int {
    return input.map(it + 1)
}))
assert v.parse(changed, [1, 2])! == [2, 3]
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
