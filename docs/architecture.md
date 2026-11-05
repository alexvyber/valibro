# Architecture and ownership

The public facade is `valibro`, with `types`, `schemas`, `actions`, `methods`,
`json`, `jsoncodec`, `unicode`, and `storages` submodules. The unpublished `utils`
compatibility module has been removed. Installed imports add the `alexvyber` publisher prefix.

## Public facade

The root module groups forwarding functions by responsibility:

| File | Ownership |
| --- | --- |
| `valibro.v` | Shared public type aliases |
| `api_schema.v` | Primitive, alternative, and native struct constructors |
| `api_checks.v` | Scalar/string/format checks and regex construction |
| `api_transform.v` | String/scalar conversions and JSON codec entry points |
| `api_collections.v` | Collection schemas, measurements and array operations |
| `api_presence.v` | Presence wrappers, defaults, fallbacks, and unwrapping |
| `api_execution.v` | Parsing, composition, functions, async, cache and contexts |
| `api_metadata.v` | Annotations, examples, brands, flavors, readonly |

Factories are grouped into cohesive files in `actions`. Shared validation helpers
stay module-private; generated format patterns live in
`actions/upstream_patterns_generated.v`. Add a factory to its owning feature file
rather than creating a file for every small function.

## Dependency direction

`types` owns the public generic contracts, value representations, their methods,
boxing, dispatch primitives and message resolution. It has no imports from other
Valibro modules. Keeping type-owned primitives here preserves compatibility and
avoids a circular dependency between representations and execution.

`methods` orchestrates parsing and pipelines over those contracts. `schemas`
constructs typed schemas; `actions` constructs checks/transformations. `json`
implements runtime structural schemas and adapters; `jsoncodec` owns JSON text
parsing/stringification and callback traversal.

Focused implementation modules replace the former utility catch-all:

| Module | Ownership |
| --- | --- |
| `internal.coercion` | Native/JSON/Maybe conversions and typed providers |
| `internal.comparison` | Native value equality and ordering |
| `internal.diagnostics` | Issue paths, labels, expectations, forwarded paths |
| `internal.number` | Exact native decimal rounding and compact native formatting |
| `internal.date` | Native ISO Date parsing/validation and UTC/fixed-offset display |
| `internal.url` | Native net.urllib validation and host/port checks |
| `internal.text` | Native whitespace, case boundaries, helper patterns |
| `internal.formats` | Format/checksum helpers and compatibility patterns |

Implementation code imports these owners directly and uses native map iteration.
Typed conversion contracts live in `types/conversion.v`. Ordinary JSON output and
diagnostics use UTF-8; explicit unit getters convert on demand. Pointer/sum-type
branches in value boxing and generic runners retain documented V 0.5.2 compiler
workarounds; they are independent of the removed forwarding module.

`internal` is an ownership convention enforced by our check, not a claim of
language-level access restriction. Internal modules may depend on `types`, other
internal modules, and the native Unicode module. They must not import the
root facade, schemas, actions, methods, runtime JSON schemas/codecs.
`methods` and `schemas` depend on `types` and focused internals. The architecture
check also rejects package import cycles:

```sh
v run scripts/check_architecture.vsh
```

The package builds with the standard V/C toolchain. Unicode algorithms and data
are native and bundled. No external system libraries, vendored parser engines,
C++ compiler or bootstrap step are required.

## Tests, fixtures and reference tooling

Tests are grouped under `tests/primitives`, `strings`, `collections`,
`composition`, `json`, `execution`, and `engines`. Each V test file is independent;
fixtures are shared by data files, not by cross-test helper declarations.

Fixture payloads are grouped under `tests/fixtures` by the same capabilities.
Stable corpus IDs preserve provenance across moves. The differential manifest
stays at `tests/fixtures/differential_sources.json` and records exact fixture and
generator paths, hashes and retained/excluded outcome counts. Explicit case tags
are owned by `tools/oracle/native_cases.json`; generators write selection reports
and manifest generation leaves fixtures unchanged.

`tools/oracle/corpora.json` owns corpus locations and descriptions. Shared oracle
helpers validate the pinned upstream checkout and preserve output encoding;
feature-specific generators retain their scenario logic. See
[oracle tooling](../tools/oracle/README.md). Normal consumers do not need Node or
Python. Architecture/package-check commands remain under `scripts`.

Unicode tables are generated into `unicode/tables_generated.v`; regenerate them
with `tools/unicode/generate_tables.py`. URL/Date implementations live in their owning internal modules; there is no
vendored parser engine tree. Do not manually reformat or split generated tables.

## Changing the package

Keep refactors separate from behavior changes. Preserve public signatures and
run the boundary check, full offline suite, formatter and isolated package check:

```sh
v run scripts/check_architecture.vsh
v test .
v fmt -verify .
v run scripts/check_package.vsh
```

When moving tests, generators or fixtures, update the corpus catalog and regenerate
the manifest and capability inventory. Fixture moves must retain payload bytes
unless a separately reviewed behavior change justifies regeneration. Generic
execution helpers have compiler-specific constraints; exercise mixed pointer,
sum-type, nested-struct and type-changing cases before simplifying them.
