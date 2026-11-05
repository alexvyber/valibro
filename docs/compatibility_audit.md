# Native API audit

The current API uses V results for parsing, plain native types for pipeline seeds,
application-owned options/functions/concurrency, direct JSON encoding, and explicit
missing/null JSON field policies. See [migration](native_api_migration.md).

Removed families include safe-parse/result wrappers, promises/futures, callable
containers, undefined/void/symbol values, four-state presence, brands/flavors,
readonly and identity conversion actions, duplicate collection utilities/count
vocabularies, default-state introspection, and JavaScript JSON callback protocols.

Native regression suites assert error propagation, JSON field policies, struct
encoding, exact integer equality, object boundaries, halfway/subnormal rounding,
Unicode algorithms, calendar validation, native regex/URLs, collections and partial
outputs. The [reference manifest](../tests/fixtures/differential_sources.json)
records 34,593 shared observations across 19 current corpora; retired API cases
are not counted as current compatibility evidence.

All remaining public API references require semantic descriptions, current source
signatures, and inline executable examples. The site validates links, examples,
coverage and static export with the standard V toolchain.
