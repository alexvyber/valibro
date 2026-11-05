# Native capability audit

The selected scope is useful Valibot-equivalent capabilities through native V
APIs, with explicit language differences. JavaScript URL/Date/regex behavior is
outside that scope. See [compatibility](compatibility.md) and the
[native URL/Date contract](native_url_date.md).

## Implemented capabilities and evidence

| Capability | Implementation/evidence |
| --- | --- |
| Stored schema unwrapping and wrapped shape operations | Original schema retention and checked `unwrap_as`; wrapper/composition differential suites |
| Deep JSON and exact units | Iterative traversal, optional depth guard and UTF-16 output; JSON runtime suite |
| Native precision and binary64 JSON mode | Native numeric widths/BigInts, shared JSON numeric classification, binary64 parse/stringify mode; numeric and JSON-number suites |
| Coercion and serialization providers | Typed native conversion interfaces, deferred key-aware JSON providers, replacer ordering and failures; provider/interaction suites |
| Failure output across type changes | Checked NativeValue boxes, InvalidDate, RawArray/Set/Map/Object/Struct views; raw-output suites |
| Equality and identity | SameValueZero for floats, type-owned boxed equality, arbitrary-key EntryMap, explicit comparators; collection/equality suites |
| Presence/default composition | Distinct states, computed defaults, Maybe coercion/serialization and parse-to-stringify pipelines; presence/default/Maybe suites |
| Struct JSON encoding | Recursive fields/providers, tags, options, embeds and fixed arrays; struct JSON suite |
| Native union failures | Aggregate failures retain original input, single candidates retain their partial result; 10,368 union cases including nested structs |
| Nested struct partial values | Child raw overrides survive typed failures and nesting; named generic runners avoid V callback specialization failures |
| Date schema diagnostics | Calendar validation, supported epoch bounds, original raw inputs and canonical issue/message fields; 504 shared validation cases |
| Native words | Unicode 17 default UAX #29 boundaries, letter/number segment counts, official word-break conformance and native action tests; no dictionary tailoring |
| Native cleanup | Pure V exact decimal rounding/remainders, scalar string lengths/order, native map keys/order, explicit conversions and native JSON struct serialization; native cleanup suites |
| Native regex | V standard-library engine, stateless matching, native modifiers, precompiled reuse and rejection tests; two explicit native ASCII Base64 overrides |
| Native URL | Absolute URI parsing, DNS/IPv4/IPv6/port checks, no repair, input preservation and error tests |
| Native Date parsing/display | Strict ISO calendars, UTC defaults, fixed offsets, nanosecond preservation, deterministic ISO strings and native composition tests |
| Package structure | Grouped facades/actions, focused internal owners, compatibility delegates, grouped tests and dependency-boundary checks |
| Consumer installation | Isolated VPM namespace and direct source build, without a parser bootstrap or prebuilt archive |

## Deliberate native boundaries

- V's static types and fixed structs; runtime JSON schemas cover heterogeneous data.
- Native precision and equality, with explicit binary64/identity/comparator adapters.
- UTF-8 strings and explicit unit-oriented JSON/error helpers where needed.
- Native Date calendar values and the ISO/UTC/fixed-offset contract; no legacy
  JavaScript grammar, browser normalization, named-zone transition logic or Date
  display-name emulation.
- Native V regex syntax and matching; no JavaScript regex state or grammar layer.
- Native struct tags, immutable JSON holder snapshots and explicit provider hooks.
- Scoped contexts, packed function arguments, Futures/channels, marker types and V
  immutability instead of JavaScript global/prototype/type-level protocols.
- Compiler profile: V 0.5.2 is tested. Fixed arrays can require slices when V's
  callback/boxing ABI fails. Word counts use bundled Unicode 17 default boundaries.

These are current API choices, not an assertion that V cannot implement other
models. Concrete mismatches within a selected native contract remain bugs.

## Evidence and reproduction

The manifest records **121,780 differential outcomes across 40 corpora**. Native
Date/URL/regex conformance tests complement those comparisons. Date-related
reference rows are restricted by an explicit shared native scope; retired
JavaScript-specific parser/display corpora are removed from current counts.
Native-only expected behavior is not relabeled as Valibot output.

All 272 runtime-function exports remain mapped through native APIs or documented
profiles. Mapping is availability evidence, not a parity percentage. The suite
currently passes **64 test files**.

```sh
v test .
v fmt -verify .
v run scripts/check_architecture.vsh
v run scripts/check_package.vsh
```

Ordinary tests run offline. Maintainer oracle generators and provenance are under
`tools/oracle`; normal consumers require neither Node nor Python. There are no
additional system-library dependencies, vendored parser sources or C++ bootstrap requirements.
