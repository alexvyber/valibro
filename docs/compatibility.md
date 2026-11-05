# Native scope and reference evidence

Valibro is a native V validation library. Full Valibot/JavaScript compatibility
is not a target. The [API inventory](../site/reference.json) describes the current
public declarations; [migration](native_api_migration.md) documents removed APIs.

Native results, options, type identity, functions, mutability and concurrency use
V constructs. Runtime JSON retains its real missing/null/value distinctions.
Numeric conversions preserve exact rounding; native integer equality and encoding
retain supplied digits. UTF-8, Unicode 17, strict calendar validation, native regex
and URL checks retain their documented behavior.

The [reference manifest](../tests/fixtures/differential_sources.json) records
34,593 retained observations across 19 still-used corpora. Checked-in rounding
and Unicode conformance data provide additional evidence. Each reference corpus
has explicit scope, hashes and reviewed native-only case accounting. Test-only
adapters normalize historical diagnostic/numeric spelling where documented;
production APIs do not emulate JavaScript.

Corpora and generators for removed presence wrappers, promises/callable containers,
marker types, array utilities and JSON callbacks are retired. Counts describe
concrete retained evidence and never establish exhaustive equivalence.

Run the tests, docs checker, formatting, architecture and isolated consumer checks
listed in the [README](../README.md). No network or parser bootstrap is needed for
ordinary builds and tests.
