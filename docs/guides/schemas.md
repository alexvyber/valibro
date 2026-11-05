# Schemas and native values

`Schema[I, O]` validates a statically known V input and can transform it to another native type. `schema[T]()` starts a typed pipeline without pretending to perform a dynamic type check. Runtime unknown values use [JSON schemas](/guides/json/).

```v
import valibro as v
import valibro.types
import math
import math.big
import time

assert v.parse(v.schema[int](), 42)! == 42
assert v.is_valid(v.boolean(), true)!
assert v.is_valid(v.bigint(), big.integer_from_int(42))!
assert !v.is_valid(v.number(), math.nan())!
assert v.is_valid(v.date(), time.Time{year:2024, month:2, day:29})!
assert !v.is_valid(v.date(), time.Time{year:2023, month:2, day:29})!
choices := v.union([v.literal('yes'), v.literal('no')])
assert v.parse(choices, 'yes')! == 'yes'
assert !v.is_valid(v.picklist([1,2,3]), 4)!
lazy := v.lazy(fn () types.Schema[string, string] { return v.pipe(v.string(), v.non_empty()) })
assert v.parse(lazy, 'ready')! == 'ready'

```

`string` checks UTF-8. `number` targets f64 and rejects NaN; add `finite` to reject infinities. `number_of[T]` preserves native widths. `nan` accepts only NaN. `literal` and `picklist` compare native values. `never` rejects every input. `custom` applies a predicate. `lazy_with` selects a schema from the input.

Blob and File hold bytes and metadata; their constructors do not access the filesystem. Use [typed objects](/guides/objects/) to validate struct fields. Handle [V options](/guides/presence/) with ordinary language constructs.
