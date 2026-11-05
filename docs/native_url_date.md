# Native URL and Date behavior

URL and Date handling is implemented in V. It uses `net.urllib`, native IPv6
parsing, Gregorian arithmetic, and `time.Time`. No parser engine is vendored and
no C++ compiler, static archive or bootstrap step is required. The package builds
with the standard V toolchain and requires no additional system libraries.

## URLs

`url()` validates absolute URIs and preserves the input string. It makes no
network requests. Supported inputs include:

```text
https://example.com/path?x=1#fragment
https://user:password@example.com:443/a%20b
http://127.0.0.1:8080/
https://[2001:db8::1]/
https://xn--bcher-kva.example/путь
mailto:alex@example.com
file:///tmp/example
data:text/plain,hello
custom:value
```

HTTP/HTTPS/FTP/WS/WSS require `://` and an authority with a host. Hosts must be
ASCII DNS-style labels, a strict four-part decimal IPv4 address, or a bracketed
IPv6 address. DNS labels use letters, digits and hyphens, with no empty labels or
leading/trailing hyphens. Punycode labels are accepted as ASCII; Unicode hostnames
are not converted. Ports must be decimal values from 0 to 65535; an explicit
empty port is rejected. IPv6 zone identifiers are not supported.

File URIs require `//` and an absolute path, with an optional valid host. Other
schemes may use a nonempty opaque part or a valid hierarchical authority/path.
Relative references and an empty scheme-specific value are rejected.

All inputs require valid UTF-8. Raw ASCII whitespace/control characters,
backslashes and malformed percent escapes are rejected, including in queries.
Unicode paths/queries are allowed. No trimming, slash repair, IDNA conversion,
IPv4 shortcut expansion, escaping or canonicalization is performed.

Consequently browser-repaired inputs such as `https:example.com`,
`http:///example.com`, `http://127.1/`, raw spaces and Unicode hosts are rejected.
This is a native validation contract, not WHATWG URL-constructor equivalence.

## Date text parsing

`to_date()` accepts these calendar forms:

```text
YYYY-MM-DD
YYYY-MM-DDTHH:MM
YYYY-MM-DD HH:MM:SS
YYYY-MM-DDTHH:MM:SS.fffffffffZ
YYYY-MM-DDTHH:MM:SS+02:30
```

Years have four decimal digits, including year zero. Month/day are validated
against the Gregorian calendar. The separator may be `T`, `t` or a single space.
Seconds are optional; a fractional part requires seconds and contains 1–9 digits.
Hours are 0–23; minutes/seconds are 0–59. Leap seconds and `24:00` rollover are
rejected. Whitespace is not trimmed; incomplete dates, extra text and invalid
calendar days are rejected.

An omitted offset means **UTC**, independent of the process timezone. Explicit
`Z`/`z` or `±HH:MM` offsets normalize the result to UTC. Offset hours are 0–23 and
minutes 0–59. Nanosecond fractions are retained rather than rounded to milliseconds.

Supply an explicit `Z`/`z` or numeric `±HH:MM` offset in text when needed.
IANA timezone names, locale parsing and daylight-saving transition rules are not
implemented. The old `utils` Date/UTF-16 adapters are removed; public pipelines
accept native text and `time.Time`.

Numeric conversions use epoch milliseconds within calendar years -999999 through
999999. Native Date schemas validate/rebuild calendar values within that range
and preserve native nanoseconds. Date-to-number/BigInt
conversions use milliseconds. Conversion failure retains `types.InvalidDate`;
a schema validation failure retains the original native Time value.

Legacy numeric strings (`42`), slash dates, month names, weekday/GMT strings,
signed extended-year text, compact offsets (`+0230`) and calendar rollover are
outside the text-parsing contract. Typed/epoch values can still represent years
outside the four-digit text-input range.

## Date display and JSON

`to_string_from[time.Time]()` use a deterministic ISO UTC
display, for example `1970-01-01T00:00:00.000Z`. It uses three fractional digits
when milliseconds suffice, otherwise nine. Invalid native dates display as
`Invalid Date`; no weekday labels, locale zone names or equivalent-year mapping
are generated.

Use `to_string_from[time.Time]()` for native UTC display and standard V formatting
for another application-specific representation. The `utils` helpers are removed. JSON Date serialization keeps
its UTC ISO representation and existing invalid-Date-to-null behavior.

## Verification

`tests/engines/native_dates_test.v` and `tests/engines/url_test.v` cover the native
contracts, including rejects, boundaries, fixed offsets, precision, pipeline
composition and input preservation. Differential fixtures retain comparable
Valibot outcomes; retired browser/legacy Date corpora are not counted as current
parity evidence. Native-only behavior is checked against explicit expectations.

Typed Date validation and epoch conversion now support calendar years -999999
through 999999. JavaScript TimeClip bounds are removed. Null/boolean/collection
Date conversions fail; Date JSON preserves nanoseconds. See
[native behavior](native_behavior.md) for migration.
