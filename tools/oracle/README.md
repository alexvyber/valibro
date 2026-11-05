# Reference data maintenance

The native V test suite runs offline against checked-in reference observations,
rounding cases, and Unicode data. The library and site require only the V toolchain.
Maintainer scripts here require Node and a pinned Valibot 1.5.0 checkout at
`d72f76fcf70ccfa0a5ca341b80da1d440ac60b11`; they are not runtime dependencies.

The native API cleanup retires corpora and generators for removed presence,
Promise/callable, marker, collection-utility, and JSON callback APIs. Remaining
corpora are listed in `corpora.json`; their scope and hashes appear in
`tests/fixtures/differential_sources.json`. The manifest counts only suites still
used by current V tests. It does not claim full Valibot compatibility.

`native_cases.json` records exact reviewed observation IDs for deliberate native
language differences. IDs hash recursively key-sorted complete observations.
New untagged observations remain included; stale or conflicting IDs fail.
Selection never changes reference expected values. Native behavior has independent
V regressions, including JSON precision and object/field boundaries.

```sh
node tools/oracle/generators/composition/generate_native_union_fixtures.mjs /path/to/valibot
node tools/oracle/generate_differential_manifest.mjs /path/to/valibot
VALIBRO_UPSTREAM=/path/to/valibot node --test tools/oracle/native_cases_test.mjs
```

Manifest generation reads fixtures and selection reports without rewriting them.
Tests verify that property and independently verify hashes and accounting in V.
Numeric spelling and historical UTF-16 units are adapted only in test support;
production code uses native numeric formatting and UTF-8 diagnostics.
