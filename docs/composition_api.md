# Native composition API

Use the [collections guide](guides/collections.md), [typed object guide](guides/objects.md), [native options and JSON field policies](guides/presence.md), and [parsing guide](guides/execution.md).

Native schemas validate V values; unknown runtime structures use the [JSON module](guides/json.md). JSON objects, records and variants require maps, not arrays. Integer equality preserves all supplied native digits, including mixed signed/unsigned comparisons. Mixed integer/float equality requires the same mathematical value.

Parse returns a native V result. Advanced inspection retains issues and boxed partial values. Runtime callback errors propagate through parse, inspect and is_valid. Defaults for native options are chosen in application code; JSON optional fields can specify a literal default.

The library has no custom parse-result container, promise layer, undefined/symbol/void values, four-state native presence wrappers, brands/flavors, identity conversions, JavaScript-style JSON callback protocol, or generic copies of ordinary collection mapping/filtering/sorting operations.
