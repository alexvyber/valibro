# Native scope and compatibility evidence

Valibro provides native V equivalents of Valibot 1.5.0 capabilities. The reference
revision is `d72f76fcf70ccfa0a5ca341b80da1d440ac60b11`. JavaScript runtime behavior
is not the implementation target. The [inventory](capabilities.json) maps public
runtime functions to native APIs; availability is not a behavioral-parity percentage.

## Current native contracts

| Area | Native contract |
| --- | --- |
| Values | `Schema[I, O]` for typed V inputs; runtime JSON schemas for heterogeneous values |
| Presence | Explicit missing/undefined/null/value `Maybe[T]` states |
| Collections | Native maps, ordered Set, arbitrary-key EntryMap, selectable equality/identity |
| Structs | Fixed V layouts and explicit field schemas, with nested partial raw outputs |
| Regex | V `regex.pcre` subset, stateless UTF-8 searches, native i/m/s modifiers, strict anchors |
| URLs | Native `net.urllib` absolute-URI validation with explicit host/port/escape checks |
| Dates | Native strict ISO calendar parsing, UTC defaults, explicit fixed offsets, native ISO display |
| Numbers | Native integer/BigInt precision; opt-in binary64 JSON semantics |
| Text | Unicode 17 casing, normalization, grapheme and default word algorithms (no locale dictionaries) |
| JSON | Revivers, source spans, immutable holder snapshots, replacers, native providers and V struct tags |
| Execution | Packed native functions, channels/Futures, worker parsing and bounded synchronized caches |
| Configuration | Scoped Context snapshots and language-specific message tables |

The package builds with the standard V/C toolchain. There are no additional
system-library dependencies, vendored parser engines, parser static archives,
C++ compiler requirements or bootstrap step. See [installation](install.md).

## URL, Date and regex differences

URL and Date validation use their own documented native contracts, described in
[native_url_date.md](native_url_date.md). In particular:

- URLs are not repaired or normalized like browser URLs. Supply explicit schemes,
  valid authorities, percent escapes and ASCII/Punycode hosts. Relative inputs,
  raw ASCII whitespace/backslashes, malformed ports and IPv4 shortcuts are rejected.
- Date text uses four-digit ISO calendars with valid days and optional time,
  nanosecond fractions and explicit offsets. Omitted offsets mean UTC regardless
  of the process timezone. Legacy numeric/month-name dates, rollover, named IANA
  timezones and JavaScript Date display conventions are outside scope.
- Date string conversion is ISO UTC, with native precision. Numeric Date conversions
  use the native calendar range, years -999999 through 999999. Typed native dates
  may represent years outside the four-digit text-input range.
- Regex uses the V engine, with no JavaScript grammar/state layer. Lookarounds,
  pattern backreferences, Unicode property/set escapes and JS-only flags are not
  part of this API. Built-in BIC/domain/emoji checks use native predicates.
- Word counts use Unicode 17 default UAX #29 segmentation and count segments
  containing letters or numbers. Locale/dictionary tailoring is outside scope;
  see [Unicode behavior and migration](unicode_api.md).
- Base64 uses the ASCII alphabet. Two non-ASCII JavaScript-folding cases have
  explicit overrides in `tests/fixtures/strings/native_format_profile.json`.

Native URL/Date/regex conformance tests supply explicit acceptance, rejection,
precision and error expectations. Retired browser URL and JavaScript Date/regex
corpora are not counted as current compatibility evidence.

## Composition, conversion and diagnostics

Native `_from` conversions support scalar, Maybe, array, Date, BigInt and supported
JSON values. Typed conversion providers return native values directly. Collections use native string representations and require explicit numeric/Date
conversions. Null is not a number or Date; strings use native boolean conversion. Date strings
inside these conversions use the native ISO contract.

Native integer/Date nanosecond precision is retained where documented. Native
value equality is the default; explicit comparators model application identities.
Numeric sets use SameValueZero and normalize signed zero. TypeScript-only helpers,
JavaScript prototype/instance identity and ecosystem packages are outside the
runtime-function inventory.

`.output` is success-only. `.raw_output` retains actual failure output, including
original values across type changes and heterogeneous partial array/set/map/struct
views. Runtime exceptions propagate through `parse`/`safe_parse_checked` separately
from validation issues. Nonfallible `safe_parse` panics on runtime exceptions.

Issues use native snake_case codes, structured paths and nested issues. Flatten
keeps native map keys without prototype setters; unsupported dot paths use its
`other` group. Message precedence and metadata are covered by context tests.
Native parser diagnostic prose is allowed to differ from JavaScript's.

## JSON and runtime boundaries

JSON callbacks receive immutable holder snapshots and source context instead of
JavaScript `this` or live property traps. Presence-aware replacers can recover
undefined. Native Maybe values unwrap recursively; missing entries are absent,
explicit undefined can reach replacers and null stays null.

Serialization is iterative, without a default explicit depth cap. A positive
`max_depth` enables a guard. Exact UTF-16 serialization/issue-unit APIs preserve
units where required; ordinary strings remain valid UTF-8. Native structs follow
V tags and recursively invoke providers; an explicit whole-object encoder wins.
Unchanged descendant projections retain deferred hooks after parent replacement.
BigInt callback substitution requires an explicit conversion to a JSON value.

Prototypes, proxies, accessors, live holder mutation, cyclic objects, sparse JS
slots and mutable Date objects are outside the selected native model. Function
arguments are packed in native types. Futures/channels replace Promise execution.
Scoped contexts replace process-global mutable configuration. Caches use explicit
input keys; identified message callbacks retain identity, while bare function
callbacks bypass storage.

## Verification and limits

Run `v test .`, `v fmt -verify .`, `v run scripts/check_architecture.vsh` and
`v run scripts/check_package.vsh`. No parser bootstrap or network access is needed
for ordinary tests. Unicode data is bundled, so word counts do not depend on
installed libraries, locale settings or dictionaries.

The [differential manifest](../tests/fixtures/differential_sources.json) records
**121,780 outcomes across 40 corpora**, along with pinned reference versions,
fixture paths/hashes and generator paths. Reviewed case-ID exclusions are applied during generation and reported separately.
Manifest generation reads fixtures without rewriting them; oracle-only numeric spelling adapters
keep production formatting independent. Date-related oracle generators retain
only comparable rows through `tools/oracle/shared/native_scope.mjs`. Word-action
comparisons explicitly exclude Japanese/Thai dictionary tailoring. Native-only
behavior is tested independently rather than fabricated as Valibot output.

Additional suites cover native URL/Date/regex contracts, numeric parsing/formatting,
formats, official Unicode conformance, native word counts, compiler contracts and package
installation. The suite currently contains **64 passing test files**. Coverage
counts describe concrete evidence and do not establish exhaustive equivalence.
See [native behavior and migration](native_behavior.md), the [implementation audit](compatibility_audit.md) and individual API guides.
