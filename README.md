# Valibro

Composable, Valibot-inspired validation written in V, using the V standard
library only. Build and test with the normal V toolchain; no external packages,
native libraries, or C++ compiler are required. Tested with V 0.5.2.

## Quick start

```v
import valibro as v

username := v.pipe(
    v.string(),
    v.trim(),
    v.to_lower_case(),
    v.min_code_points(3, 'Use at least three characters'),
    v.max_code_points(32),
    v.regex(r'^[a-z0-9_]+$'),
)

result := v.safe_parse(username, '  Alex  ')
if result.success {
    output := result.output or { return }
    println(output) // alex
} else {
    for issue in result.issues {
        println('${issue.code}: ${issue.message}')
    }
}
```

`v.string()` accepts native, well-formed UTF-8 strings. Wrong native input types
are compile-time errors; malformed UTF-8 returns a schema issue.

## Capabilities

- String lengths in UTF-8 bytes, Unicode code points, or UTF-16 code units,
  with exact/minimum/maximum/exclusion checks.
- Prefixes, suffixes, substrings, literal values, membership, and comparisons.
- Email, domain, IP/MAC, ISO formats, identifiers, encodings, and checksum validators.
- HTTP(S), WS(S), and FTP URL validation with documented host/port/escaping rules.
- Regular expressions through V's pure V `regex.pcre` module.
- Trimming, simple Unicode casing, and camel/Pascal/kebab/snake case formatting.
- Typed number, bigint, boolean, date, and JSON conversions.
- Custom validators/transformations, issue-aware messages, annotations, and brands.

See the [API and supported behavior](docs/string_api.md). This library implements
selected Valibot concepts with native V contracts; it does not claim full Valibot
or JavaScript-runtime parity.

Advanced Unicode normalization, grapheme segmentation, locale-aware word counting,
and emoji validation are deferred. They have no placeholder implementations in
the core. Casing uses V's simple mappings, so `Straße` uppercases to `STRAßE`.

## Typed conversions

`v.pipe` composes same-type actions. `v.pipe_to` changes the schema's output type:

```v
number := v.pipe_to(v.string(), v.to_number())
value := v.parse(number, '42') or { panic(err) } // f64
println(value)

boolean := v.pipe_to(v.string(), v.parse_boolean())
flag := v.parse(boolean, 'YES') or { panic(err) } // bool
println(flag)
```

`safe_parse` returns `success`, optional `output`, and structured `issues`.
Failed validation always has absent output. `parse` returns `!O`; its
`types.ValidationError` retains the issues. The `_with_config` variants accept
`v.Config{abort_early: true}`. Otherwise consecutive validations collect issues;
transformations stop after any issue, and fatal failures stop all later actions.

Use `v.message_fn(fn (issue v.Issue) string { ... })` for dynamic messages.
Canonical extension types live in `valibro.types`: `Schema[I, O]`, `Action[T]`,
`Transformation[I, O]`, `Dataset[T]`, and `Issue`.

## Modules

```text
valibro*.v   Public facades: import valibro as v
schemas/     Base schema factories
actions/     One file per validation, transformation, or metadata feature
methods/     Composition and parsing
types/       Shared generic contracts, configuration, errors, annotations
utils/       Pure V regex, URL, casing, patterns, and checksum helpers
tests/       All tests and reference fixtures
examples/    Runnable public API examples
scripts/     Optional upstream fixture regeneration
```

Facades import feature modules; feature modules use shared types and utilities.
Shared types do not depend on feature modules. The executor operates on common
contracts without switching on built-in action names. Consumers can also import
`valibro.actions`, `valibro.schemas`, and `valibro.methods` directly.

## Verification

```sh
v test .
v fmt -verify .
v run examples/username
v run examples/strings
```

The checked-in tests need V only. Selected upstream fixtures cover 2,046 format
outcomes, 275 transformations, and 29 measurement inputs. Native URL, casing,
regex, conversion, and extension contracts have separate regression tests.

## Migration from the native-dependency prototype

Ada, ICU, their build flags, and their adapters have been removed. The advanced
Unicode factories (`normalize`, `emoji`, and the `graphemes`/`words` families)
were removed from the public API. URL validation now follows the supported rules
in the API notes. Regex uses V syntax with `$` as the end anchor; former `\z`,
Unicode property escapes, lookarounds, and backreferences are unsupported.

`length` still counts UTF-16 code units for Valibot familiarity: `🙂` has length 2,
4 bytes, and 1 code point. Choose `code_points` for character-oriented limits.

## License

MIT. See `LICENSE` and `THIRD_PARTY_NOTICES.md` for the remaining adapted Valibot
patterns, algorithms, and fixture attribution.
