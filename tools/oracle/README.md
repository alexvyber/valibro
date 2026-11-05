# Differential oracle tooling

Maintainer tools evaluate Valibot 1.5.0 at
`d72f76fcf70ccfa0a5ca341b80da1d440ac60b11`. Normal V builds/tests use checked-in
fixtures offline and require neither Node nor an upstream checkout.

Run generators from the repository root with Node 24.14.1 and the pinned checkout
as their first argument. Shared loading checks the package version and Git revision.
`corpora.json` records corpus paths, generator owners and scope.

```sh
node tools/oracle/generators/composition/generate_native_union_fixtures.mjs /path/to/valibot
node tools/oracle/generate_differential_manifest.mjs /path/to/valibot
node tools/oracle/generate_capability_inventory.mjs /path/to/valibot
VALIBRO_UPSTREAM=/path/to/valibot node --test tools/oracle/native_cases_test.mjs
```

Generators are grouped under primitives, strings, collections, composition, JSON,
execution and engines. Shared reference helpers validate/load upstream and preserve
issue observations. Availability counts do not establish exhaustive parity.

## Explicit native-only cases

`native_cases.json` owns reviewed case IDs, native-contract tags, descriptions and
input scenario summaries. IDs hash the complete observation using recursively
key-sorted JSON. A changed expectation changes its ID. New untagged observations
are retained by default; generation fails on stale IDs, unknown or conflicting
tags. There are no blanket filters for empty strings, Unicode, or object key names.

`shared/native_cases.mjs` selects exact tagged cases during generation and writes
both the retained fixture and its sibling `.native.json` report. Reports record
candidate, retained and excluded row/outcome counts, per-tag totals and excluded
IDs. Step-based corpora distinguish row counts from outcome counts. Original
Valibot expected values are never rewritten into native expected values.

To document a new native-only scenario, add its exact observation ID and a reviewed
contract tag, add a native V regression test, regenerate the owning corpus, then
regenerate the manifest. Do not add a general input-content exclusion predicate.
The old heuristic selector is removed. The cleanup restored 3,970 valid composition
comparisons that broad filters had unnecessarily discarded.

The `json_object_boundary` tag records exactly 5,012 reviewed observations whose
JavaScript arrays-as-objects behavior differs from native JSON map boundaries:
4,760 composition, 84 custom-check, and 168 legacy structural observations.
Only changed observations are tagged; retained observations remain unchanged.
The legacy structural corpus is now included in the manifest and exact-case
accounting. Native boundary/composition/callback behavior is tested independently
in `tests/json/json_precision_boundaries_test.v`.

The manifest command reads fixtures, selection reports and registry hashes. It
writes only the manifest. The tool tests verify that fixtures, reports, registry
and generators remain byte-identical. V metadata tests independently check hashes,
case tags and accounting offline. Maintainer tool tests use Node's built-in runner
and no npm dependencies; only the manifest integration test needs the pinned
checkout through `VALIBRO_UPSTREAM`.

Some generators explicitly limit their candidate domain, such as supported ISO
Date input and default word segmentation. Those scopes are documented in the
catalog and `shared/native_scope.mjs`; retired browser/legacy Date and Array.join
corpora remain outside the native model. Native-only contracts have separate V
tests and are not counted as Valibot comparisons.

`tests/support/reference.v` adapts numeric spelling solely for reference-value
comparisons. Production code never imports it. JSON comparisons may ignore object
order and numeric spelling; native tests assert their actual native behavior.

Unicode generation remains separate at `tools/unicode/generate_tables.py`; it uses
flattened Unicode 17 UCD files with recorded source hashes and licenses. Format
pattern generation updates only the generated pattern table.
