# Native V API migration

This breaking API cleanup removes JavaScript-shaped runtime abstractions. Numeric rounding, native integer precision, Unicode algorithms, calendar validation, and the JSON object boundary fixes remain in place.

- Use parse(schema, input, Config) and native V error handling. There is no SafeParseResult, safe_parse family, parser factory or panic-based validity wrapper.
- Use inspect for Dataset issues and partial values. Its runtime errors propagate through V results.
- Use native options and if/or for typed absence and defaults. V 0.5.2 cannot instantiate Schema[?I, ?O]; there is no replacement presence container.
- JSON optional handles missing fields; nullable handles null. Compose them for both, and use FieldConfig.default_value for a literal missing-field default.
- Use schema[T]() for a typed pipeline seed. Any/unknown native aliases, runtime instance checks, null/undefined/void/symbol schemas and enum-as-picklist aliases are removed.
- The explicit binary64_integer check replaces safe_integer; it checks interoperability limits, not native integer validity.
- Use native domain aliases/structs and mutability rules. Readonly, brand and flavor APIs are removed.
- Assign context.config directly and use Context message methods with an explicit language. Context-taking global storage helpers and their module are removed.
- Metadata factories are generic: title[T], description[T], examples[T], and metadata[T]. Their string-specialized aliases are removed.
- Cache options use a native trailing CacheConfig; cache_with_config is removed.
- Use ordinary functions and application-owned threads/channels. Promise/Future and callable-container APIs are removed.
- Use try_transform for native fallible callbacks, and transform/transform_to for ordinary callbacks.
- Use V array/map operations for mapping, filtering, finding, reducing and sorting. Indexed collection validation remains; length_of and its variants are the collection-count vocabulary.
- JSON parsing/encoding retains exact numeric handling and formatting options. Revivers, replacers, holder snapshots, deferred toJSON hooks, root omission and UTF-16 convenience APIs are removed. Use explicit preprocessing and standard V JSON encoder interfaces.

There are no deprecated aliases implementing the removed API. Documentation and API inventory describe the current declarations rather than claiming full Valibot compatibility. Obsolete reference suites for removed features are retired; remaining fixtures and native regression suites retain their actual tested scope.
