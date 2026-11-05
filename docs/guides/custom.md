# Custom validation

Use `custom[T]` for a predicate schema, `check[T]` for an action, and `guard[T]` for a same-type guard action. In native V these preserve the declared type; they do not narrow a TypeScript union.

## Predicates

```v
import valibro as v

schema := v.pipe(v.number_of[int](), v.check(fn (value int) bool {
    return value % 2 == 0
}, 'Must be even'))
assert v.is_valid(schema, 4)!
assert v.inspect(schema, 3)!.issues[0].message == 'Must be even'
assert v.is_valid(v.custom(fn (value string) bool {
    return value == 'ready'
}), 'ready')!
```

## Dataset-aware actions

`raw_check` returns issues for one value. `raw_check_with_context` receives the current dataset and config, so it can preserve partial output and inspect previous issues. A dataset can carry issues or an explicit runtime exception. Use the provided issue constructors rather than fabricating malformed diagnostics.

```v
import valibro as v
import valibro.types

schema := v.pipe(v.number_of[int](), v.raw_check(fn (value int) []types.Issue {
    if value < 0 {
        return [types.new_issue('positive', 'Use a positive number', '>=0', value.str())]
    }
    return []types.Issue{}
}))
assert v.is_valid(schema, 1)!
assert v.inspect(schema, -1)!.issues[0].code == 'positive'
```

## Cross-field dependencies

`partial_check` declares paths needed by a predicate. It can run when those dependencies are valid, even if unrelated fields have issues. A missing or invalid dependency prevents the predicate from consuming a misleading typed value. Paths are native string keys and integer array indexes.

```v
import valibro as v
import valibro.types

schema := v.partial_check(v.array(v.number_of[int]()), [[types.PathSegment(0)],
    [types.PathSegment(1)]], fn (values []int) bool {
    return values.len >= 2 && values[0] == values[1]
}, 'Values must match')
assert v.is_valid(schema, [2, 2])!
assert !v.is_valid(schema, [2, 3])!
```

For custom transformations use `transform`, `transform_to`, or dataset/context variants of `raw_transform`. See [transformations](/guides/transforms/) and [errors](/guides/errors/).
