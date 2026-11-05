# Changelog

## [0.0.0-dev.1] - 2026-11-05

Development prerelease of `alexvyber.valibro` for native V. The API is experimental
and may change between development releases.

- Typed native schemas, validation actions, type-changing pipelines, collections,
  nested structs, validation fallbacks, and scoped configuration/messages.
- Native error handling through `parse(...) !T`, `inspect(...) !Dataset[T]`, and
  `is_valid(...) !bool`; fallible callbacks through `try_transform`.
- Runtime JSON object/tuple policies, alternatives, intersections, variants,
  recursive schemas, shape operations, native adapters, and explicit missing/null
  field policies.
- Exact numeric rounding, precision-preserving native integer encoding,
  arbitrary-precision BigInt conversions, and JSON object boundary regressions.
- Bundled Unicode 17 normalization, casing, grapheme, word, and emoji algorithms;
  native URL, regex, and strict calendar validation.
- JSON encoding with V struct tags, native options, conversion providers,
  formatting controls, and optional binary64 projection.
- Structured issues, partial raw outputs, generic metadata, and bounded LRU caching.
- Native V documentation site with 540 public API references, 569 total pages,
  executable examples, syntax highlighting, search, static export, and Markdown
  endpoints. No browser JavaScript or external VPM dependencies.
- Checked-in offline differential fixtures and native/Unicode conformance tests.
- Source-only VPM packaging, an isolated consumer check, and Linux/macOS CI.

The former JavaScript-shaped compatibility layer is removed: custom safe-parse
results, promise/Future and callable containers, undefined/void/symbol schemas,
custom native presence states, readonly/brands/flavors, redundant collection
helpers, JSON revivers/replacers, and deferred hooks. Use native V errors,
options, domain types, callbacks, collection operations, and application-owned
threads. See the [migration guide](docs/native_api_migration.md).

JavaScript regex compatibility has been removed. `regex` and `regex_with_flags`
use V's `regex.pcre`; the latter accepts native `i`, `m`, and `s` modifiers only.
`compile_regex` returns a native `Regex` value, usable with `find` or
`regex_object`. UTF-16 regex construction, the `RegExp`/`RegexLimits` types,
stateful indices, and JavaScript execution budgets are removed. Built-in format
validators use native patterns/predicates and their documented native scope.

URL/Date parser engines and their bootstrap/static archives have been removed.
URL validation follows the documented native URI profile; Date text parsing is
strict ISO with UTC/fixed offsets and native ISO display, without browser repair,
legacy date grammar, IANA timezone parsing or JavaScript display conventions.

ICU and its regex API have been removed. Word actions use native Unicode 17
default boundaries without locale dictionaries; locale-selecting `_in` word
factories have been removed. See the Unicode guide for migration and examples.

Remaining C numeric bridges have been removed. Exact decimal-to-binary64 rounding
and floating remainders use native V. String lengths/order, map keys/order,
conversions, indentation, container serialization and Date ranges now follow the
[native contract](docs/native_behavior.md), with dedicated regression tests.

Typed conversion providers replace string hints and boxed primitive dispatch.
Date providers preserve exact integer milliseconds; boolean conversion rejects
unsupported types. Path forwarding follows existing keys/indices. f32 formatting
retains native precision, and ordinary JSON/diagnostic output uses UTF-8 directly.
The `utils` compatibility module and trivial map/UTF-16 forwarding helpers are
removed. Oracle generation uses reviewed case IDs and separate exclusion reports;
manifest generation never rewrites fixtures, and valid overfiltered comparisons
have been restored.

Requires only V 0.5.2 and its standard C toolchain. See
[installation](docs/install.md), [compatibility](docs/compatibility.md), and
[third-party notices](THIRD_PARTY_NOTICES.md).
