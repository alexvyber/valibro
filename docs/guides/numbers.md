# Numbers and bounds

Native numeric schemas retain their declared types. Use `number()` for `f64` or `number_of[T]()` for another native numeric type. Requirements must match: `min_value(0.0)` for `f64`, `min_value(0)` for `int`.

## Integer and range checks

`finite`, `integer`, and `safe_integer` default to `f64`; `_of[T]` variants cover other native numeric types. Safe integers lie in the inclusive range from -9007199254740991 through 9007199254740991. Native wide-integer checks do not round their inputs.

```v
import valibro as v

age := v.pipe(v.number(), v.finite(), v.integer(), v.min_value(0.0), v.max_value(130.0))
assert v.parse(age, 42.0)! == 42.0
assert !v.is_valid(age, 1.5)!
count := v.pipe(v.number_of[int](), v.multiple_of(2), v.gt_value(0), v.lt_value(100))
assert v.is_valid(count, 42)!
assert !v.is_valid(count, 41)!
```

`min_value` and `max_value` are inclusive; `gt_value` and `lt_value` are exclusive. Value comparisons and clamps also support native strings, dates, and big integers. String ordering follows V and dates retain nanoseconds.

## Membership and clamps

`value` and `values` accept exact requirements. `not_value` and `not_values` reject them. Floating membership treats NaN as equal to NaN. Lists of requirements are copied. An empty positive membership list rejects all inputs.

```v
import valibro as v

choice := v.pipe(v.number_of[int](), v.values([2, 4, 8]))
assert v.is_valid(choice, 4)!
assert !v.is_valid(choice, 3)!
clamp := v.pipe(v.number_of[int](), v.to_min_value(0), v.to_max_value(100))
assert v.parse(clamp, -10)! == 0
assert v.parse(clamp, 110)! == 100
```

## Remainders and conversion

`multiple_of` uses exact native remainder checks, without an epsilon. Consequently `0.3` is not accepted as a floating multiple of `0.1`. Zero and NaN divisors cause issues. Big-integer division by zero is a runtime error; use `inspect` to catch it.

```v
import valibro as v

assert v.is_valid(v.pipe(v.number(), v.multiple_of(0.5)), 1.5)!
assert !v.is_valid(v.pipe(v.number(), v.multiple_of(0.1)), 0.3)!
schema := v.pipe_to(v.string(), v.to_number())
assert v.parse(schema, '0x2a')! == 42.0
assert !v.is_valid(schema, '')!
```

Decimal text conversion uses exact ties-to-even binary64 rounding. Native integers, BigInt values, and integer epoch milliseconds retain their native precision until an explicit binary64 conversion is requested. See [transformations](/guides/transforms/) and [native behavior](/guides/native-behavior/).
