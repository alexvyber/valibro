# Strings and formats

Start with [string](/api/string/) and add checks through [pipe](/api/pipe/). Checks preserve the input. Trimming, normalization, and casing are explicit transformations.

## Length and content

`length`, `min_length`, `max_length`, and `not_length` count code points on strings. Byte, code-point, grapheme, and word actions expose their measurement explicitly. Empty strings pass the base schema; use `non_empty` to reject them.

```v
import valibro as v

schema := v.pipe(v.string(), v.trim(), v.min_length(3), v.max_length(20),
    v.starts_with('a'), v.excludes(' '))
assert v.parse(schema, '  alex  ')! == 'alex'
assert !v.is_valid(schema, 'a')!
assert v.is_valid(v.pipe(v.string(), v.bytes(4), v.code_points(1), v.graphemes(1)), '🙂')!
```

`starts_with`, `ends_with`, `includes`, and `excludes` check literal text. `value` and `values` compare entire values, with exclusion counterparts. See [Unicode](/guides/unicode/) for normalization and word boundaries.

## Common formats

The format actions include email/RFC email, domains, absolute URLs, IP addresses, MAC addresses, UUID/ULID/CUID2/KSUID/nanoid, ISO dates and times, encodings, colors, payment/identifier checksums, hashes, and compact JWS structure. These validate the format; they do not establish ownership, deliverability, authenticity, or reachability.

```v
import valibro as v

assert v.is_valid(v.pipe(v.string(), v.email()), 'alex@example.com')!
assert !v.is_valid(v.pipe(v.string(), v.email()), 'not-an-email')!
assert v.is_valid(v.pipe(v.string(), v.ipv4()), '192.0.2.1')!
assert v.is_valid(v.pipe(v.string(), v.hex_color()), '#aabbcc')!
assert v.is_valid(v.pipe(v.string(), v.iso_date()), '2024-02-29')!
assert v.is_valid(v.pipe(v.string(), v.url()), 'https://example.com/path')!
```

ISO date/time actions check textual component ranges; they do not prove Gregorian calendar validity. For example, `iso_date` accepts `2023-02-29` as a shape, while `to_date` rejects that nonexistent date. Use a Date conversion/schema for calendar validation.

## Native regular expressions

`regex` accepts a native `regex.pcre` pattern. `compile_regex` returns a fallible reusable regex; `regex_object` builds an action from it. `regex_with_flags` accepts native supported flags. Do not assume JavaScript RegExp syntax or stateful matching behavior.

```v
import valibro as v

compiled := v.compile_regex(r'^[a-z][a-z0-9_]+$', '')!
schema := v.pipe(v.string(), v.regex_object(compiled))
assert v.is_valid(schema, 'alex_7')!
assert !v.is_valid(schema, '7alex')!
```

## Reference

Browse [checks and format actions](/api/actions/), [root factories](/api/), and [native behavior](/guides/native-behavior/).
