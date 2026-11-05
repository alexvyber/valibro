# Changelog

## [0.2.0] - Unreleased

Prepared for publication as `alexvyber.valibro` on VPM.

- Typed primitive schemas, validation actions, type-changing pipelines, native
  collections, nested structs, presence states, defaults, and fallbacks.
- Runtime JSON object/tuple policies, alternatives, intersections, variants,
  recursive schemas, shape operations, and native adapters.
- Numeric checks and conversions with native precision and arbitrary BigInts.
- Unicode 17 normalization, casing, grapheme handling, native default word counts, and
  Valibot-compatible format validators.
- Native V URL and strict ISO Date parsing; native V regex validation;
  native Unicode word segmentation. No external system-library dependency.
- Configurable JSON revivers/replacers, native providers, presence handling,
  binary64 mode, and explicit UTF-16 interfaces.
- Structured errors and partial raw outputs, scoped messages/configuration,
  metadata, function contracts, Futures, worker parsing, and bounded LRU caching.
- Mapping of all 272 Valibot 1.5.0 public runtime function exports, with documented
  native representation choices. The mapping is not a proof of exhaustive parity.
- Checked-in offline differential fixtures and engine/Unicode conformance tests.
- Grouped public facades/actions, focused internal implementation modules,
  feature-organized tests/fixtures, and shared oracle tooling; public signatures
  and module imports are retained.
- VPM metadata, installation/release guides, and an isolated consumer package
  check exercised by Linux/macOS package CI.

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
