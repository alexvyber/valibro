# Types and lower-level APIs

The root module is the normal entry point. Public implementation modules remain importable for advanced integrations: `schemas`, `actions`, `methods`, `types`, `storages`, `jsoncodec`, and `unicode`. Modules under `internal` are implementation details and are not part of this reference inventory.

## Core contracts

`Schema[I, O]` runs with a `Config` and returns `Dataset[O]`. `Action[T]` operates without changing the declared output type; `Transformation[I, O]` changes it. A dataset carries its current value, typed state, issues, optional raw value, and optional runtime exception.

Use constructors and factories whenever possible. Public fields with `@[required]` need explicit initialization; some public structs contain internal storage and should be obtained through their factories.

```v
import valibro.schemas
import valibro.actions
import valibro.methods
import valibro.types

schema := methods.pipe(schemas.number_of[int](), actions.min_value(0))
dataset := types.run(schema, -1, types.Config{})
assert dataset.typed
assert dataset.value == -1
assert dataset.issues.len == 1
assert !methods.safe_parse(schema, -1).success
```

## Native values

`NativeValue` is a boxed inspection view, used for partial/failure output. `value_of` boxes a native value; `value_is[T]` tests its native type; `value_as[T]` is fallible. `RawArray`, `RawObject`, `RawMap`, and `RawSet` represent mixed partial output without inventing a success-only typed value.

```v
import valibro.types

boxed := types.value_of[int](42)
assert types.value_is[int](boxed)
assert types.value_as[int](boxed)! == 42
assert types.some('ready').state == .value
assert types.missing[string]().state == .missing
```

## Interfaces and callbacks

Conversion providers return native number, bigint, boolean, date, or string values. `Countable` exposes a native size. JSON value providers return explicit serializable values. Pipeline runners and generic presence interfaces support package integration and are not an implicit coercion protocol.

Issue constructors create structured validation diagnostics. Message callbacks receive issues; stable identities matter when caching them. Context setters mutate only the context supplied by the caller.

## Module reference

- [Root API](/api/): convenience factories and aliases.
- [schemas](/api/schemas/): native schema implementations.
- [actions](/api/actions/): checks, transformations, formats, and annotations.
- [methods](/api/methods/): composition, execution, errors, defaults, and caches.
- [types](/api/types/): public data types, interfaces, constructors, and receiver methods.
- [storages](/api/storages/): scoped context settings and messages.
- [json](/api/json/): dynamic structural schemas.
- [jsoncodec](/api/jsoncodec/): native parsing and serialization configuration.
- [unicode](/api/unicode/): versioned Unicode algorithms and constants.
