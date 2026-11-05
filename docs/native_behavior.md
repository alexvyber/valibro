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
of splitting surrogate pairs. Ordinary actions and diagnostics use valid UTF-8.

Trimming uses V's Unicode whitespace predicate, without a separate ECMAScript
whitespace table. In the tested V version NEL is whitespace and BOM is not.
Case transformations classify whole Unicode characters, including supplementary
letters. Unicode normalization, grapheme and default word algorithms are retained.

## Native API and conversions

Parse returns a native V result. Inspect exposes issues and partial values;
callback errors propagate through parse, inspect and is_valid. Native options,
functions, domain types and concurrency are handled directly by the application.
See [migration](native_api_migration.md) for removed APIs and replacements.

Conversions target explicit native types. Numeric parsing retains the exact
rounding algorithm above. Arrays/maps do not implicitly become numbers or Dates.
Typed conversion providers return native target values directly. Integer epoch
milliseconds retain every digit, including beyond binary64's exact-integer range.

## JSON and object boundaries

JSON objects, records and variants require maps; arrays are never projected into
numeric-keyed objects. Native map keys, including constructor/prototype names,
are ordinary keys. Native iteration order is retained.

JSON optional handles missing fields and nullable accepts explicit null. A native
V option uses its ordinary if/or handling. No undefined or four-state native value
model is provided.

Runtime-schema parse_text shares jsoncodec.decode and exact float rounding at all
nesting depths. Native JSON integer equality compares exact signed/unsigned values;
a float equals an integer only if their mathematical values match exactly.
Recursive JSON equality keeps NaN unequal, while membership treats NaNs as equal.
Signed zeros compare equal under both policies.

Dynamic integer-token representation follows x.json2, which can choose f64.
Use explicit integer decoding or strings plus BigInt for exact large input values.
Native integer serialization stays exact unless binary64 projection is selected.
Float output uses native compact spelling; nonfinite values serialize as null.

Encoding visits native struct fields, arrays, maps, pointers and options directly.
V JSON tags and standard encoder interfaces select representations. Native time
values retain nanoseconds. Functions and unsupported values must be converted
explicitly. There are no revivers, replacers, deferred toJSON phases, property-list
options or UTF-16 convenience APIs. Encoding remains iterative with an optional
positive depth guard and integer/string indentation.

## Dates and diagnostics

Date text uses strict ISO calendars with four-digit years, UTC defaults and
explicit fixed offsets. Typed calendar values support years -999999 through
999999. Invalid fields and timestamps beyond the supported native range fail.
See [native URL and Date behavior](native_url_date.md).

Structured issue paths distinguish native string keys and integer indexes.
Forwarding stops at the deepest existing prefix. Dot paths are display text;
use structured segments when exact key identity matters.

## Verification

Native API, numeric precision, JSON boundary, Unicode, calendar, regex, URL and
collection tests run through the standard V toolchain. The retained reference
manifest counts only corpora still used by current tests. Removed API corpora
are retired rather than translated into claims of full Valibot compatibility.
