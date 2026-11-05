# Primitive schemas and numeric checks

Import `valibro as v`, or use `valibro.schemas`, `valibro.actions`, and
`valibro.methods` directly. All primitives use `Schema[I, O]`, `pipe`, `parse`,
and `safe_parse`. See the [build requirements](install.md).

## Schemas

| Factory | Native input/output | Behavior |
| --- | --- | --- |
| `number(message?)` | `f64` | Rejects NaN; accepts infinities |
| `number_of[T](message?)` | Native numeric `T` | Preserves native precision; floating types reject NaN |
| `boolean(message?)` | `bool` | Static native boolean contract |
| `bigint(message?)` | `math.big.Integer` | Arbitrary precision |
| `date(message?)` | `time.Time` | Valid Gregorian fields and supported epoch range |
| `nan(message?)` | `f64` | Accepts NaN only |

Native type mismatches fail at compile time. Use `valibro.json` for runtime type
validation. Factories accept at most one message string or `v.message_fn`.
Schema failures are untyped; validation issues can retain a typed dataset.
`safe_parse` exposes `.typed` and `.issues`, with absent `.output` on failure.

```v
import valibro as v

age := v.pipe(v.number(), v.finite(), v.integer(), v.min_value(0.0), v.max_value(130.0))
assert v.parse(age, 42.0) or { panic(err) } == 42.0
assert !v.safe_parse(age, 1.5).success
count := v.pipe(v.number_of[int](), v.min_value(0), v.multiple_of(2))
assert v.parse(count, 42) or { panic(err) } == 42
```

Requirements select the action type. Use `0.0` with `f64`, `0` with `int`, and
explicit casts for other native numeric types. No implicit numeric conversion
is performed between native pipeline types.

`number_of`, numeric checks, bounds, clamps, membership, and typed conversions
support `isize` and `usize` as well as fixed-width integers. Their width follows
the V target. Safe-integer checks compare without rounding; `multiple_of(-1)`
handles the signed minimum safely. Number conversion explicitly uses binary64; Date conversion retains integer
epoch milliseconds; BigInt and ordinary integer serialization retain native
precision. Zero is false for pointer-width integers, just as for other numbers.

Runtime JSON schemas and conversions accept every numeric `json2.Any` alternative,
including `i8`, `i16`, `i32`, `u8`, `u16`, and `u32`. Numeric boolean conversion, boolean parsing,
Date conversion from epoch milliseconds, numeric equality, and set deduplication
use the same scalar rules across representations. JSON adapters accept these
representations for number inputs and preserve supported integer output types;
`isize`/`usize` outputs project to `i64`/`u64`. Typed conversion providers return their target native type directly. Differential fixtures cover representable inputs;
on 32-bit targets the harness skips values outside the native width.

## Numeric checks

| Action | Acceptance |
| --- | --- |
| `finite(message?)` | Finite binary64 values |
| `integer(message?)` | Finite binary64 values without fractional parts |
| `safe_integer(message?)` | Integers in `[-9007199254740991, 9007199254740991]` |
| `multiple_of(n, message?)` | Exact zero remainder |

The first three actions default to `f64`; `_of[T]` variants support other native
numeric types. Wide-integer safe-range checks preserve integer precision.
Both signs of zero are accepted. `integer` can accept representable whole
numbers beyond the binary64 safe-integer range.

Numeric zero/NaN divisors produce validation issues. Infinite divisors accept
zero; negative divisors are supported. Big-integer division by zero raises
`RangeError` through `parse`/`safe_parse_checked`; fallbacks preserve exceptions.
Signed integer minima with divisor `-1` are handled without overflow.
Floating multiples use `fmod` without an epsilon: `1.5` is a multiple of `0.5`,
while `0.3` fails `multiple_of(0.1)`.

## Values, bounds, and clamps

`value`, `not_value`, `values`, and `not_values` accept strings, native numbers,
booleans, big integers, and dates. Floating membership uses SameValueZero,
including NaN. Lists are copied. Empty `values` rejects all inputs;
empty `not_values` accepts all inputs.

`min_value`, `max_value`, `gt_value`, `lt_value`, `to_min_value`, and `to_max_value`
accept strings, native numbers, big integers, and dates. Minimum/maximum bounds
are inclusive; greater/less bounds are exclusive. Clamps are transformations.
Date value issues use ISO timestamps, with extended signed years where needed.
Native submillisecond dates retain a nine-digit fractional display.
Strings use native V ordering. Native integer comparisons stay exact. Floating
bounds follow IEEE-754 comparisons. Native dates preserve nanosecond precision.

Validation errors preserve values within the dataset and collect in order until
an abort setting or transformation boundary. Bounds use expected strings such as
`>=10`; exclusions use `!5`. Finite/integer/safe-integer issues have an empty
expected field (the native representation of upstream null). Factory message
callbacks receive canonical issue fields and the parsing configuration.

```v
whole := v.pipe(v.number(), v.integer('Use a whole number'))
assert v.safe_parse(whole, 1.5).issues[0].message == 'Use a whole number'
```

## Dates and conversions

`date` validates Gregorian calendar fields, year zero, leap days and nanoseconds.
Valid fields rebuild cached timestamps while preserving `is_local`. Invalid
fields, leap seconds and `time.Time{}` fail. Typed calendars support years -999999
through 999999; text uses strict four-digit ISO dates, UTC defaults and explicit
numeric offsets. Native integer epoch milliseconds and nanoseconds remain exact.
See [native Date behavior](native_url_date.md).

`to_number` parses decimal/radix text with exact ties-to-even binary64 rounding;
empty text fails. `to_bigint` retains arbitrary precision. `to_boolean` uses V's
`string.bool()`. `parse_boolean` validates recognized spellings and supports
custom lists. Numeric booleans test nonzero; arrays/maps and `Countable` values
test nonempty. Unsupported structs and Dates produce boolean conversion issues.
`to_boolean_from[T](message?)` supports custom factory/config messages.

Arrays/maps do not implicitly become numbers or Dates. Null numeric/Date
conversions fail, and booleans are not Dates. Native arrays and JSON collections
use native string representations. A key named `toString` has no special effect.
`f32` string conversion uses its own shortest representation (`0.1` stays `0.1`)
instead of widening to `f64`; Number conversion still explicitly produces `f64`.

Use `transform_to` for one-off conversions. Reusable native types can implement
one or more contracts from `valibro.types`:

| Contract | Method |
| --- | --- |
| `NumberProvider` | `to_number() !f64` |
| `BigintProvider` | `to_bigint() !big.Integer` |
| `DateProvider` | `to_date() !time.Time` |
| `StringProvider` | `to_string() !string` |
| `BooleanProvider` | `to_boolean() !bool` |

Providers return the target type directly. Date providers preserve native
precision without an intermediate floating conversion. Their returned calendars
are validated. Provider errors become conversion issues; custom messages and raw
failure outputs remain available.

```v
import valibro as v
import time

struct Event {
    occurred_at time.Time
}

pub fn (event Event) to_date() !time.Time {
    return event.occurred_at
}

fn main() {
    schema := v.pipe_to(v.unknown[Event](), v.to_date_from[Event]())
    value := v.parse(schema, Event{time.unix_nanosecond(0, 1)}) or { panic(err) }
    assert value.nanosecond == 1
}
```

The string-hint primitive provider API and the `utils` compatibility module have
been removed. Applications should use the public constructors/actions and typed
providers above. Internal modules are implementation details. For fixed arrays,
use a dynamic slice if V 0.5.2 cannot box/pass the array through a schema callback.

Present `Maybe[T]` values unwrap recursively. Missing/undefined numeric and Date
conversions fail; null is not zero or the epoch:

| State | Number | BigInt | Boolean | Date | String |
| --- | --- | --- | --- | --- | --- |
| missing / undefined | Issue | Issue | false | Issue | `undefined` |
| null | Issue | Issue | false | Issue | `null` |
| value | Convert contained value | Convert contained value | Convert contained value | Convert contained value | Convert contained value |

```v
import valibro as v
import valibro.types

schema := v.pipe_to(v.optional(v.string()), v.to_number_from[types.Maybe[string]]())
assert v.parse(schema, types.some('42')) or { panic(err) } == 42.0
assert !v.safe_parse(schema, types.missing[string]()).success
```

Factory/config messages retain their precedence. `.output` is success-only;
`.raw_output` retains original/partial failures according to the transformation.
Date text failures have an explicit `InvalidDate` marker; schema failures retain
the original native Time. JSON parsing uses exact decimal rounding for float
tokens and retains integer alternatives when the native decoder supplies them.
The tested `x.json2` decoder can select `f64` for integer text; disabling binary64
mode does not guarantee exact large-integer parsing. Explicit native integer
values retain precision when serialized without binary64 projection.

See [native behavior and migration](native_behavior.md) for the complete contract.
