# Schemas and native values

A native `Schema[I, O]` accepts input type `I` and produces output type `O`. V checks input types at compilation. Use [runtime JSON schemas](/guides/json/) for values whose shape is unknown until runtime.

## Primitives

`string` validates UTF-8. `number` accepts `f64` except NaN, including infinities; add `finite` when infinities should fail. `number_of[T]` preserves a native numeric type. `boolean`, `bigint`, and `date` work with their corresponding native types.

```v
import valibro as v
import math.big
import time

assert v.safe_parse(v.boolean(), true).success
assert v.safe_parse(v.number_of[int](), 42).output? == 42
assert v.safe_parse(v.bigint(), big.integer_from_int(42)).success
assert v.safe_parse(v.date(), time.Time{year: 2024, month: 2, day: 29}).success
assert !v.safe_parse(v.date(), time.Time{year: 2023, month: 2, day: 29}).success
```

`nan` accepts only NaN. `null_schema`, `undefined_schema`, and `void_schema` accept the explicit native marker types. `symbol` accepts identity-bearing native symbols; equal descriptions do not imply equal identities. `instance[T]` expresses a static native type, without a runtime prototype check. `blob` and `file` validate the package's native data containers.

## Literal values and alternatives

`literal` accepts one value. `picklist` and `enum_schema` accept a supplied list. Native `union` alternatives must share input and output types. For heterogeneous alternatives, use the JSON adapter.

```v
import valibro as v
import valibro.types

choices := v.union([v.literal('yes'), v.literal('no')])
assert v.parse(choices, 'yes')! == 'yes'
assert !v.safe_parse(choices, 'maybe').success
assert v.safe_parse(v.picklist([1, 2, 3]), 2).success
assert v.safe_parse(v.null_schema(), types.Null{}).success
assert v.safe_parse(v.symbol(), types.symbol('request')).success
```

## Accepting, rejecting, and deferring

`unknown[T]` and `any_value[T]` preserve a native value. `never[T]` rejects every value of its input type. `custom[T]` checks a predicate. `lazy` defers schema construction; `lazy_with` can select a schema from the input. Use them for recursive or input-dependent structures, avoiding infinite construction loops.

```v
import valibro as v
import valibro.types

schema := v.lazy(fn () types.Schema[string, string] {
    return v.pipe(v.string(), v.non_empty())
})
assert v.safe_parse(schema, 'ready').success
assert !v.safe_parse(schema, '').success
assert !v.safe_parse(v.never[int](), 1).success
assert v.parse(v.unknown[int](), 7)! == 7
```

## Reference

Browse [root schemas and factories](/api/), [schema implementations](/api/schemas/), [typed objects](/guides/objects/), and [presence wrappers](/guides/presence/).
