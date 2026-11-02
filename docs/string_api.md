# String API and supported behavior

Valibro is a pure V library with V standard-library dependencies. Its schema,
action, and pipeline model is inspired by Valibot. Its supported behavior is
described here; matching names alone do not imply JavaScript or Valibot parity.

## Formats

These factories accept an optional string message or `v.message_fn` callback:

| Category | Factories |
| --- | --- |
| Encoding / character formats | `base64`, `decimal`, `digits`, `hexadecimal`, `hex_color`, `octal`, `slug` |
| Contact / network | `email`, `rfc_email`, `domain`, `url`, `ip`, `ipv4`, `ipv6`, `mac`, `mac48`, `mac64` |
| Identifiers | `bic`, `cuid2`, `nanoid`, `ksuid`, `ulid`, `uuid`, `isrc`, `jws_compact` |
| Checksums | `credit_card`, `imei`, `isbn` |
| ISO formats | `iso_date`, `iso_date_time`, `iso_date_time_second`, `iso_time`, `iso_time_second`, `iso_timestamp`, `iso_week` |

`hash([.sha256, .sha512], message?)` checks hexadecimal representation and length
for selected algorithms. `v.HashType` supports `md4`, `md5`, `sha1`, `sha256`,
`sha384`, `sha512`, `ripemd128`, `ripemd160`, `tiger128`, `tiger160`, `tiger192`,
`crc32`, `crc32b`, and `adler32`. At least one algorithm is required.

Email and format patterns derive from the inspected Valibot source snapshot.
`rfc_email` uses its HTML-style rule, not every RFC 5322 mailbox spelling.
`domain` accepts ASCII multi-label domains with an alphabetic TLD of at least two
letters, excluding Punycode labels. BIC has explicit ASCII/length/location checks.
ISO validators check spelling and numeric ranges, not calendar validity:
`iso_date` can accept February 31. `credit_card`, `imei`, and `isbn` also check
their corresponding checksums.

## URL rules

`url(message?)` validates an absolute hierarchical URL using V's `net.urllib`
parser plus explicit validation:

- Supported schemes: HTTP, HTTPS, WS, WSS, FTP, case-insensitively.
- An explicit `://` authority and nonempty host are required.
- ASCII DNS-style host labels, `localhost`, Punycode supplied as ASCII,
  conventional dotted-decimal IPv4, and bracketed IPv6 are accepted.
- Host labels contain letters, digits, and internal hyphens, with a 63-byte limit
  per label and a 253-byte limit for the host. A trailing host dot is rejected.
- An explicit port must contain decimal digits with a value from 0 through 65535.
- Control characters, whitespace, backslashes, and malformed percent escapes are
  rejected throughout the input. Spaces must be percent-encoded.
- UTF-8 paths/query text are accepted. Unicode host conversion and IPv6 zone
  identifiers are unsupported.

Examples accepted: `https://example.com/a%20b`, `ws://localhost:8080`,
`https://[2001:db8::1]/`. Examples rejected: `https:example.com`,
`http://example.com:65536`, `mailto:alex@example.com`, `file:///tmp/x`, and bare
Unicode hosts. There is no browser-style input repair, default base URL, network
request, or WHATWG parsing claim. Opaque/custom schemes need a custom validator.

## Measurements and content

| Family | Exact | Minimum | Maximum | Exclusion |
| --- | --- | --- | --- | --- |
| UTF-16 code units | `length(n)` | `min_length(n)` | `max_length(n)` | `not_length(n)` |
| UTF-8 bytes | `bytes(n)` | `min_bytes(n)` | `max_bytes(n)` | `not_bytes(n)` |
| Unicode code points | `code_points(n)` | `min_code_points(n)` | `max_code_points(n)` | `not_code_points(n)` |

Each accepts an optional message. Counts must be non-negative integers.
`🙂` is two UTF-16 code units, four bytes, and one code point. A base character
followed by a combining accent is two code points; no grapheme counting is implied.

Other validators:

- `empty(message?)`, `non_empty(message?)`: empty contents, without trimming.
- `starts_with`, `ends_with`, `includes`, `excludes`: literal substrings.
- `value`, `not_value`: literal equality; `values`, `not_values`: membership in a
  copied string list.
- `min_value`, `max_value`, `gt_value`, `lt_value`: UTF-16 lexicographic ordering,
  including supplementary characters.
- `regex(pattern, message?)`: search for a regular-expression match.

## Regular expressions

The standard-library module `regex.pcre` is implemented in V; it does not link to
the native PCRE library. Patterns compile once per schema factory and matching
uses per-call state. Supported syntax includes groups/noncapturing groups,
character classes, UTF-8 literals and ranges, repetition, alternation, `^`/`$`,
word boundaries, named `(?P<name>...)` groups, and inline `(?i)`/`(?m)`/`(?s)` flags.

Use `r'^[a-z]+$'` for a whole ASCII string, `r'[0-9]'` to search for a digit, or
`r'^[а-яё]+$'` for an explicit Cyrillic range. `$` is strict end-of-input by default;
`(?m)` enables line-oriented anchors.

Lookarounds, Unicode property escapes (`\p`/`\P`), `\z`/`\Z`, `\u` escapes,
backreferences, and native-engine extensions are unsupported. The adapter rejects
these forms during construction instead of silently interpreting them as literals.
Other syntax and matching limits follow the bundled V engine. There is no ICU
time limit or hard wall-clock execution guarantee. Avoid untrusted arbitrary
patterns; fixed library patterns are covered by the format tests.

## Transformations

Use these with `v.pipe`:

| Factories | Behavior |
| --- | --- |
| `trim`, `trim_start`, `trim_end` | ECMAScript whitespace, including BOM/NBSP |
| `to_lower_case`, `to_upper_case` | V's simple Unicode mappings |
| `to_camel_case`, `to_pascal_case`, `to_kebab_case`, `to_snake_case` | Separator/acronym/digit boundaries with V casing |
| `to_min_value`, `to_max_value` | Clamp using UTF-16 lexicographic ordering |
| `to_string` | Identity for native strings |
| `stringify_json` | Quote and escape a string as JSON |
| `readonly` | Preserve the value; V strings already have immutable contents |

Simple casing does not expand characters or apply context-sensitive mappings.
For example, `Straße` becomes `STRAßE`, `ﬁ` remains `ﬁ` when uppercased, and `ΟΣ`
lowers to `οσ` without Greek final-sigma handling. Cyrillic simple mappings such
as `ёж` → `ЁЖ` work. These details follow V's Unicode tables.

Normalization, extended grapheme segmentation, locale-aware word segmentation,
and emoji validation are deferred. Their former factory names have been removed
rather than retained as approximations or no-op actions. A future Unicode module
should have a justified implementation, versioned data, and dedicated conformance
tests before it becomes part of the API.

## Typed conversions

`types.Schema[I, O]` preserves input and output types. `v.pipe_to(schema, action)`
changes the output type; `v.pipe(schema, actions...)` can validate that output.

| Factory | Output | Behavior on strings |
| --- | --- | --- |
| `to_number(message?)` | `f64` | Decimal/exponent, unsigned radix prefixes, Infinity, whitespace-to-zero; rejects NaN/partial parses |
| `to_bigint(message?)` | `math.big.Integer` | Signed decimal, unsigned radix prefixes; arbitrary precision |
| `to_boolean()` | `bool` | Every nonempty string is true |
| `parse_boolean(message?)` | `bool` | Case-insensitive true/false, 1/0, yes/no, y/n, on/off, enabled/disabled |
| `parse_boolean_with_config(config, message?)` | `bool` | Custom truthy/falsy string lists |
| `to_date(message?)` | `time.Time` | V's ISO 8601 / RFC 2822 parsing |
| `parse_json(message?)` | `x.json2.Any` | Strict JSON into V-native values |
| `stringify_json_value[T]()` | `string` | JSON serialization of a typed V/JSON value |
| `brand[B]()` | `types.Branded[string, B]` | Immutable value wrapper with a marker type |
| `flavor[B]()` | `types.Flavored[string, B]` | Separate immutable value wrapper with a marker type |

`parse_boolean` does not trim; truthy takes precedence if custom lists overlap.
JSON uses V's native numeric types and serialization conventions. Dates do not
emulate JavaScript's legacy date grammar. Brands/flavors are V wrappers with a
`.value` field; they do not implement TypeScript intersection or soft-subtype
semantics.

## Customization and metadata

- `check(fn (T) bool, message?)`: validation.
- `guard(fn (T) bool, message?)`: fatal refinement.
- `raw_check(fn (T) []types.Issue)`: structured issues, including custom paths.
- `transform(fn (T) T)` / `raw_transform(fn (T) types.Dataset[T])`: same-type
  transformations, optionally with issues.
- `transform_to(fn (I) O)` / `raw_transform_to(fn (I) types.Dataset[O])`:
  type-changing custom transformations through `pipe_to`.

Return `typed: false` for fatal custom conversion failures. Parsing enforces that
a fatal result cannot expose a successful output, even if a callback omits its
issues. By default, consecutive validation actions collect issues. Early abort or
a transformation boundary stops further work after an issue.

Messages accept strings or callbacks adapted with `v.message_fn`. The latter
receives the structured issue. `v.message(action, message)` copies a same-type
action and overrides its messages. Conversion factories accept messages directly.

`title(text)`, `description(text)`, `examples([]string)`, and
`metadata(map[string]json2.Any)` annotate a schema. Later annotations override
like-named values; metadata maps merge by key. Metadata actions are skipped
during execution. Read them using `get_title`, `get_description`, `get_examples`,
and `get_metadata`.

## Test provenance and scope

Selected reference fixtures were evaluated against Valibot revision
`d72f76fcf70ccfa0a5ca341b80da1d440ac60b11` (package version 1.5.0):

- 2,046 format outcomes from the retained shared format rules.
- 275 transformations across supported shared behavior; casing comparisons use
  ASCII inputs. Native simple Unicode casing has explicit regression tests.
- 29 measurement inputs tested across three metrics and four bounds at three
  thresholds (1,044 comparisons).

URL behavior has its own acceptance/rejection tests, including intentional
scope boundaries, rather than an expectation of WHATWG equivalence. Regex,
conversion, customization, annotations, malformed UTF-8, and error propagation
also have independent tests. Tests live under `tests/` and run with `v test .`.

The corpus is evidence for the tested behavior, not proof of full Valibot parity.
Advanced Unicode and opaque-URL cases are excluded by explicit scope, with no
runtime fallback to external implementations.

Fixture regeneration is optional maintainer work. With Node 24, an upstream
checkout at the revision above, and a TypeScript parser installation:

```sh
node scripts/generate_parity_fixtures.mjs /path/to/valibot /path/to/typescript/lib/typescript.js
v test .
```

Normal builds and tests use the included fixtures and require V only.
