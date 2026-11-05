# Native behavior

Valibro provides native V validation. It does not recreate the JavaScript runtime, browser URL repair, JavaScript Date parsing, or JavaScript regex execution.

## Strings and regex

Native strings must be valid UTF-8. String length/order and whitespace behavior follow documented native policies. Regex uses V's `regex.pcre` syntax and flags; unsupported JavaScript patterns must be rewritten. No QuickJS or ICU regex API is included.

```v
import valibro as v

schema := v.pipe(v.string(), v.regex(r'^[a-z]+$'))
assert v.is_valid(schema, 'alex')!
assert !v.is_valid(schema, 'ALEX')!
```

## URLs

URL validation uses native `net.urllib` parsing with explicit absolute-URI checks. Supply a valid scheme, authority where required, escaped path characters, and ASCII/punycode host names. Do not rely on a browser repairing whitespace, backslashes, incomplete authorities, or Unicode host names.

```v
import valibro as v

schema := v.pipe(v.string(), v.url())
assert v.is_valid(schema, 'https://example.com/path?q=1')!
assert !v.is_valid(schema, '/relative/path')!
```

## Dates

Text conversion accepts strict four-digit ISO dates/date-times, with UTC defaults or numeric offsets. Native `time.Time` validation checks Gregorian calendar fields and supports years from -999999 through 999999. Native dates retain nanoseconds and integer epoch milliseconds; arbitrary human date strings and JavaScript coercions are unsupported.

```v
import valibro as v

schema := v.pipe_to(v.string(), v.to_date())
output := v.parse(schema, '2024-02-29')!
assert output.year == 2024
assert output.month == 2
assert output.day == 29
assert !v.is_valid(schema, 'February 29, 2024')!
```

## Numeric precision and explicit conversions

Decimal text conversion rounds exactly to binary64 with ties to even. Native integer comparisons and ordinary integer JSON serialization retain precision. `f32` string conversion uses its own shortest representation. Arrays/maps do not implicitly join into numbers or dates; null does not become zero or the epoch.

V options, native functions and application-owned threads handle absence, calls and concurrency. See [numbers](/guides/numbers/), [presence](/guides/presence/), [JSON configuration](/guides/json-config/), and [Unicode](/guides/unicode/) for the supported contracts.
