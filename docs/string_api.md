# String API and supported behavior

Valibro uses native V regex, URL, ISO Date and Unicode word segmentation.
See [build requirements](install.md),
[compatibility evidence](compatibility.md), and [numeric schemas](primitive_api.md).

## Formats

Factories accept an optional message string or `v.message_fn` callback.

| Category | Factories |
| --- | --- |
| Encoding and characters | `base64`, `decimal`, `digits`, `hexadecimal`, `hex_color`, `octal`, `slug` |
| Contact and network | `email`, `rfc_email`, `domain`, `url`, `ip`, `ipv4`, `ipv6`, `mac`, `mac48`, `mac64` |
| Identifiers | `bic`, `cuid2`, `nanoid`, `ksuid`, `ulid`, `uuid`, `isrc`, `jws_compact` |
| Checksums | `credit_card`, `imei`, `isbn` |
| ISO formats | `iso_date`, `iso_date_time`, `iso_date_time_second`, `iso_time`, `iso_time_second`, `iso_timestamp`, `iso_week` |

`hash([.sha256, .sha512], message?)` checks hexadecimal representation and length.
`HashType` supports `md4`, `md5`, `sha1`, `sha256`, `sha384`, `sha512`,
`ripemd128`, `ripemd160`, `tiger128`, `tiger160`, `tiger192`, `crc32`, `crc32b`,
and `adler32`. At least one algorithm is required.

Built-in format patterns and flags match the pinned upstream snapshot.
`rfc_email` follows its HTML-style rule, rather than every RFC 5322 mailbox
spelling. `domain` requires ASCII labels and an alphabetic TLD of at least two
letters, excluding Punycode labels. BIC uses the upstream lookahead pattern.
ISO formats validate spelling/ranges, not calendar validity: February 31 can
pass `iso_date`. Credit-card, IMEI, and ISBN validators also check checksums.

## URLs and regex

`url(message?)` validates absolute URIs through V's `net.urllib`, with explicit
host/port/escape checks. HTTP/HTTPS/FTP/WS/WSS require an authority; file URIs need
an absolute path; nonempty opaque schemes such as mailto/data are accepted.
Hosts use ASCII DNS labels, strict IPv4 or bracketed IPv6; supply Punycode for
international hostnames. Raw ASCII whitespace, backslashes, malformed escapes,
relative inputs and browser-style repair are rejected. Validation preserves the
input and makes no network requests. See [native URL/Date behavior](native_url_date.md).

`regex(pattern, message?)` uses V's pure V `regex.pcre` implementation with
search semantics. `regex_with_flags(pattern, flags, message?)` accepts `i`, `m`,
and `s`, which map to V's inline modifiers. Inline `(?i)`, `(?m)`, and `(?s)`
patterns also work. Matching is stateless and operates on UTF-8 strings; `$`
requires the actual end of the string unless multiline mode is selected.

```v
regexp := v.compile_regex(r'(?P<letters>[A-Za-z]+)', '') or { panic(err) }
action := v.regex_object(regexp)
```

`compile_regex` returns `Regex` (a native `regex.pcre.Regex`). Use its `find`
method for direct matching. Reusing a compiled value or copying an action does
not carry match position between calls. Factories panic on invalid patterns;
`compile_regex` reports them as ordinary V errors.

The public regex contract is the V engine's supported subset. Lookarounds,
pattern backreferences, Unicode property escapes, UTF-16 regex construction,
JavaScript state/index APIs and flags `d`, `g`, `u`, `v`, `y` are not supported.
Use explicit class ranges such as `[0-9]` rather than shorthand escapes inside
character classes. No alternative regex backend is bundled.

Built-in format patterns use explicit ASCII classes and native modifiers. BIC,
domain and emoji validators use native predicates instead of lookarounds or
Unicode-property regexes. Format validation does not adopt JavaScript-specific
Unicode folding or end-anchor behavior; see [compatibility](compatibility.md).

## Measurements and content

| Metric | Exact | Minimum | Maximum | Exclusion |
| --- | --- | --- | --- | --- |
| Code points | `length` | `min_length` | `max_length` | `not_length` |
| UTF-8 bytes | `bytes` | `min_bytes` | `max_bytes` | `not_bytes` |
| Code points | `code_points` | `min_code_points` | `max_code_points` | `not_code_points` |

Each accepts an integer requirement and optional message. Negative requirements
are evaluated normally. `🙂` has length 1, four bytes, and one code point.
Grapheme and native word actions are described in [Unicode](unicode_api.md).

`empty`/`non_empty` inspect length without trimming. `starts_with`, `ends_with`,
`includes`, and `excludes` inspect literal content. Prefix/suffix failure
fragments retain whole code points. Explicit issue-unit getters remain available
for UTF-16 interoperability.

`value`/`not_value` check equality; `values`/`not_values` check a copied list.
`min_value`, `max_value`, `gt_value`, and `lt_value` use native V string
ordering. These actions also support the types listed in the primitive guide.

## Transformations and conversions

`trim`, `trim_start`, and `trim_end` use V's Unicode whitespace predicate; BOM is not stripped. `to_lower_case`/`to_upper_case` use Unicode 17 full default mappings.
Camel/Pascal/kebab/snake actions use reference separator/acronym/digit rules.
`to_min_value`/`to_max_value` clamp by native string order. Use ordinary V strings and mutability rules. stringify_json_value[string] performs
actual JSON quoting and escaping.

Use `pipe_to` for conversions that change type:

| Factory | Output | String behavior |
| --- | --- | --- |
| `to_number` | `f64` | Validated decimal/radix forms with exact rounding; empty text and NaN fail |
| `to_bigint` | `big.Integer` | Signed decimal, unsigned radix prefixes |
| `to_boolean` | `bool` | V string.bool() behavior; use parse_boolean for validation |
| `parse_boolean` | `bool` | Recognized truthy/falsy spellings, full Unicode lowercase |
| `parse_boolean_with_config` | `bool` | Custom string lists |
| `to_date` | `time.Time` | Strict ISO calendars; UTC default and explicit fixed offsets |
| `parse_json` | `json2.Any` | Strict JSON into native JSON values |
| `stringify_json_value[T]` | `string` | Typed serialization with native scalar rules |

Boolean parsing does not trim; truthy values take precedence on overlap.
Typed `_from[T]` conversions accept other native/JSON inputs. See the
[primitive guide](primitive_api.md) and [JSON configuration](guides/json-config.md).

## Extension and metadata

`check(fn (T) bool, message?)` validates; `guard` performs fatal refinement.
`transform`/`transform_to` apply same-type/type-changing callbacks.
`raw_check`, `raw_transform`, and `raw_transform_to` accept structured issues or
datasets; `_with_context` variants also receive the current dataset and Config.
Transformations stop after issues. Consecutive validations collect by default;
abort settings control later validation work and collection traversal.

Messages accept strings or `message_fn` callbacks. `message(action, text)`
overrides newly added issues. Callbacks receive canonical fields and language/
abort metadata, once at issue creation during parsing. Use `types.run`,
`types.run_action`, or `types.run_transformation` when manually executing an
extension hook and requiring resolved messages.

`title`, `description`, `examples`, and `metadata` annotate string schemas;
`_for[T]` variants support other output types. Later annotations override named
values; metadata maps merge by key. Getters expose these annotations without
executing a parse. `brand[B]`/`flavor[B]` return native marker wrappers.

## Verification

The pinned upstream version is Valibot 1.5.0, revision
`d72f76fcf70ccfa0a5ca341b80da1d440ac60b11`. Original fixtures include 2,046 format
outcomes, 275 transformations, and 29 measurement inputs. Expanded corpora compare
full errors, message callbacks, conversions, UTF-16 fragments, URL/regex engines,
and Unicode behavior. See [compatibility](compatibility.md) and fixture manifests.

Fixture regeneration is optional maintainer work; consumers need no Node.
`tools/oracle/generators/strings/generate_parity_fixtures.mjs` accepts a pinned Valibot checkout and a
TypeScript parser path. Other generators document their arguments at the top.

See [native behavior and migration](native_behavior.md) for conversion, formatting
and string-contract changes.
