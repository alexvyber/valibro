# Valibro

Composable validation for V, targeting native V equivalents of Valibot 1.5.0.
Valibro provides typed schemas, transformations, runtime JSON schemas, structured
errors, and configuration contexts. Tested with V 0.5.2.

The [inventory](docs/capabilities.json) maps all 272 public runtime exports,
including aliases and async APIs. [Compatibility and evidence](docs/compatibility.md)
describes the native value model and the tested behavior.

## Installation

VPM package: **`alexvyber.valibro`**. Version **0.2.0** is prepared for
publication; the registry command applies after registration:

```sh
v install alexvyber.valibro
```

Use `import alexvyber.valibro as v` in consumers. Checkout examples use
`import valibro as v`. See [installation](docs/install.md) and
[release preparation](docs/releasing.md).

Use V 0.5.2 and its standard C toolchain. No additional system libraries,
vendored parser engines or bootstrap steps are required. There is no handwritten
C/C++ or direct C interop in the package. URLs and Dates use
native V parsing, regex uses V's `regex.pcre`, and word counts use bundled
Unicode 17 data with native default word segmentation. See the
[native URL/Date contract](docs/native_url_date.md) and
[Unicode behavior](docs/unicode_api.md) for accepted inputs and differences.

## Quick start

```v
import valibro as v

username := v.pipe(v.string(), v.trim(), v.to_lower_case(),
    v.min_code_points(3, 'Use at least three characters'),
    v.max_code_points(32), v.regex(r'^[a-z0-9_]+$'))
result := v.safe_parse(username, '  Alex  ')
if result.success {
    println(result.output or { return }) // alex
} else {
    for issue in result.issues {
        println('${issue.code}: ${issue.message}')
    }
}
```

Native inputs are statically typed. Use `valibro.json` for unknown JSON inputs,
heterogeneous objects, tuples, unions, intersections, and discriminated unions.

```v
age := v.pipe(v.number(), v.integer(), v.min_value(0.0), v.max_value(130.0))
assert v.parse(age, 42.0) or { panic(err) } == 42.0
numbers := v.array(v.pipe_to(v.string(), v.to_number()))
assert v.parse(numbers, ['1', '2']) or { panic(err) } == [1.0, 2.0]
```

`pipe` composes same-type actions; `pipe_to` changes output type. Requirements
must match native types: `min_value(0.0)` targets `f64`, `min_value(0)` targets
`int`. Typed `_of`, `_for`, and `_from` variants retain explicit types.

Failed `safe_parse` results expose issues, typed state, and boxed `.raw_output`;
the typed `.output` is success-only.
`parse` returns `!O` and an inspectable `ValidationError`. Runtime exceptions
propagate through `parse` and `safe_parse_checked`; nonfallible `safe_parse`
panics on exceptions. Advanced callbacks can inspect partial datasets through
`types.run`, `raw_check_with_context`, and `raw_transform_with_context`.

## Guides

- [Native behavior and migration](docs/native_behavior.md)
- [Strings, formats, URLs, and regex](docs/string_api.md)
- [Primitive schemas and numeric checks](docs/primitive_api.md)
- [Collections, objects, presence, and execution](docs/composition_api.md)
- [Unicode and word segmentation](docs/unicode_api.md)
- [Compatibility, JSON callbacks, and differential evidence](docs/compatibility.md)
- [Audit of documented differences](docs/compatibility_audit.md)

## Verification

```sh
v test .
v fmt -verify .
v run scripts/check_architecture.vsh
v run examples/username
v run examples/strings
v run examples/primitives
v run examples/composition
v run scripts/check_package.vsh
```

Tests run offline. Native conformance tests cover URLs, ISO Date parsing/display and regex.
Checked-in reference fixtures cover numbers, Unicode, formats, recursive schemas, collection
failure outputs, callbacks, JSON configuration, messages, and abort behavior.
The [differential manifest](tests/fixtures/differential_sources.json) records the
reference runtime, generators, case counts, scopes, and fixture hashes: 121,780
outcomes across 40 corpora, alongside native and Unicode conformance suites.

## Layout and license

`schemas`, `actions`, `methods`, and `types` implement the typed core.
`internal` owns conversions, comparisons, diagnostics, and native adapters.
Typed conversion interfaces return native values; no compatibility forwarding
module or string-hint coercion protocol is retained.
`json` supplies runtime structural validation; `jsoncodec` supplies JSON callback
configuration. `unicode` contains Unicode 17 data and native algorithms. Public facades
live in `api_*.v`; `valibro.v` contains shared public aliases. See
[architecture](docs/architecture.md) for ownership and dependency rules.

MIT. See `LICENSE`, `THIRD_PARTY_NOTICES.md`, and `unicode/LICENSE`.
