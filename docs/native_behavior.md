# Native behavior and migration

Valibro uses V values, standard-library facilities and bundled Unicode data.
There is no runtime JavaScript layer, handwritten C/C++, foreign-function call,
external system-library dependency or bootstrap command. V's standard compiler
and libraries may themselves use C; the normal V toolchain is still required.

## Numbers

Decimal input is validated in a linear pass, converted to an exact `math.big`
integer ratio, and rounded once to binary64 using round-to-nearest, ties-to-even.
This covers halfway values, signed zero, subnormal underflow and overflow. It
avoids the rounding differences found in V 0.5.2's `strconv.atof64`, including
`9007199254740993` and `1e23`. Huge exponents are classified without allocating
huge powers of ten when overflow/underflow is already certain. Radix integers
are converted through the same exact rounding path. Floating `multiple_of` uses
native `math.fmod`; floating arithmetic retains binary rounding effects.

Number/BigInt text accepts supported decimal/radix forms after V's
`encoding.utf8.is_space` trimming. Empty text and BOM-prefixed text fail.
`Infinity` remains an explicit floating input. Number display uses V's shortest
float spelling, with an exact `.0` suffix removed for compact scalar output.
Signed zero is `-0`; diagnostic nonfinite labels are `NaN` and `Infinity`.
Examples: `1e6` displays as `1e+06`, and `1e-7` as `1e-07`.
`f32` retains its own shortest spelling instead of widening to `f64`.
The `utils` module and trivial internal forwarding adapters have been removed;
use public conversion actions or standard V operations.

## Strings

`length` and its variants count Unicode scalar values, like `code_points`.
`bytes` still counts UTF-8 bytes, and `graphemes` counts Unicode 17 grapheme
clusters. `🙂` has length 1 and byte length 4. Ordering and clamps use native V
string comparison. Prefix/suffix diagnostics retain whole code points instead
of splitting surrogate pairs. Explicit UTF-16 encoding and issue-unit helpers
remain available for interoperability; ordinary actions use valid UTF-8.

Trimming uses V's Unicode whitespace predicate, without a separate ECMAScript
whitespace table. In the tested V version NEL is whitespace and BOM is not.
Case transformations classify whole Unicode characters, including supplementary
letters. Unicode normalization, grapheme and default word algorithms are retained.

## Conversions

`to_boolean` uses V's `string.bool()` behavior (`true` and `t` are true in V
0.5.2). Use `parse_boolean` when invalid spellings should produce issues, or a
custom transformation for another policy. Numeric booleans test nonzero;
array/map/Countable booleans test nonempty. Null/missing values are false.
Dates and arbitrary structs require an explicit BooleanProvider or transformation;
unsupported inputs produce issues rather than silently becoming true.

Null is not a number or Date. Booleans are not Dates. Arrays/maps require an
explicit numeric/date conversion; there is no recursive comma joining or object
`toString` lookup. Native arrays and JSON collections use their native string
representations. A map key named `toString` has no special effect. Present
Maybe values unwrap; absent/null numeric and Date conversions fail. Explicit
typed `NumberProvider`, `BigintProvider`, `DateProvider`, `StringProvider`, and
`BooleanProvider` methods return native target values directly. String hints and
boxed primitive dispatch are removed. Date providers never round integer
milliseconds through binary64. See [provider signatures](primitive_api.md#dates-and-conversions).

## Forwarded paths

`forward` appends existing JSON map keys and integer array indexes to new issues.
It stops at the deepest existing prefix when a key/index is missing or a scalar
is reached. Zero, false, empty text and null do not affect key presence. Strings
and arrays have no simulated `length` properties; strings are not indexed as
objects, and string `"0"` is not an integer array index. Missing/null paths do not
raise runtime exceptions. Existing issue paths remain intact.

## Maps and JSON

Map iteration order is retained. Numeric-looking keys are ordinary keys;
`__proto__`, `prototype`, and `constructor` are preserved and validated like any
other key. This changes serialization order, callback order, and the first error
when early-abort validation encounters those inputs. Property lists still select
and order keys explicitly.

Indentation is an integer width or literal string. Float indentation is removed;
negative widths produce no padding. Widths/strings are not clipped to ten, and
Unicode characters are never cut in half. Ordinary output uses a UTF-8 builder;
UTF-16 output is converted only when explicitly requested. Diagnostics keep only
UTF-8 strings; `received_units()` and `message_units()` encode on demand. The old
`received_utf16`/`message_utf16` stored fields are removed. Serialization remains iterative, with
an optional explicit depth guard.

Finite JSON floats use native compact spelling and retain signed zero; nonfinite
numbers become null. Native integers remain exact. `binary64_numbers: true`
explicitly requests floating rounding for integer JSON tokens. Decimal float
parsing uses the exact native parser in both modes. JSON callback/provider APIs,
presence states and V field tags remain supported.

Set, EntryMap, Blob and File values serialize their native struct fields, including
nested providers, instead of producing empty JavaScript-style objects. For
example, a Set serializes as `{"values":[1,2]}`. Functions cannot be encoded as
JSON; Futures must be awaited first. Use an explicit provider to select another
representation. Date JSON preserves native nanoseconds.

## Dates

Date text retains the strict four-digit ISO/UTC/fixed-offset contract. Typed
calendar values support years -999999 through 999999, within the supported
V 0.5.2 date arithmetic and millisecond representation. JavaScript TimeClip bounds
are removed. Integer epoch-millisecond inputs retain their exact values beyond
binary64's safe-integer range. Invalid fields and timestamps outside the native range still fail.
See [URL and Date behavior](native_url_date.md) for parsing and display details.

## Verification

`tests/engines/native_cleanup_test.v` and
`tests/primitives/native_array_conversions_test.v` assert these native contracts.
The rounding suite retains bit-level comparisons against independent reference
observations. Differential tests compare only shared contracts; native-only
expectations are never labeled as Valibot outputs.

`tools/oracle/native_cases.json` lists reviewed observation IDs and native-only
tags. Generators select those exact cases and write separate `.native.json`
reports with retained/excluded counts and reasons. New untagged cases are included
by default; stale IDs fail generation. There are no input-content heuristics.
The cleanup restored 3,970 valid composition comparisons removed by broad filters.

`generate_differential_manifest.mjs` reads fixtures and reports without rewriting
them, and records their hashes and separate exclusion counts. Maintainer tests
verify this property. `tests/support/reference.v` normalizes numeric spelling
only for oracle comparisons; production does not import it.

The exact rounding corpus also uses explicit case IDs for its numeric-text policy
differences; the rounding test no longer skips Unicode/empty inputs heuristically.
Both simple and configured JSON float parsing use the same exact decimal parser.
