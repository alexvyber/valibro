# Caching

`cache` wraps a schema in synchronized bounded LRU storage. You choose a native key function and capacity. Configuration also contributes to the effective key, so executions with different settings do not share a result accidentally.

## Choose a key

A key must capture every input distinction that affects validation. Mutable reference-bearing inputs and outputs need particular care: cached outputs can retain references. Callback side effects do not run on cache hits.

```v
import valibro as v

schema := v.cache(v.pipe(v.string(), v.trim(), v.min_length(2)), fn (value string) string {
    return value
}, max_size: 16)
assert v.parse(schema, ' Alex ')! == 'Alex'
assert v.parse(schema, ' Alex ')! == 'Alex'
assert !v.is_valid(schema, 'x')!
```

## Capacity and expiry

`cache` accepts a trailing `CacheConfig` parameter struct: maximum size, optional maximum age in milliseconds, and an injectable clock. Capacity zero disables storage; negative capacity is rejected. Expiry occurs strictly after the configured age, so an entry at exactly the age bound remains valid. Validation failures can be cached; runtime exceptions are not cached.

## Inspect and clear

`cached` exposes the wrapped schema plus `key`, `get`, `set`, and `clear` methods. `get` returns a dataset option. `set` accepts an already-constructed dataset; do not use it to bypass validation accidentally.

```v
import valibro as v

cached := v.cached(v.string(), fn (value string) string {
    return value
}, v.CacheConfig{max_size: 2})
assert v.parse(cached.schema, 'alex')! == 'alex'
key := cached.key('alex', v.Config{})
entry := cached.get(key) or { panic('Expected a cached dataset') }
assert entry.value == 'alex'
cached.clear()
assert cached.get(key) == none
```

## Message identity

`message_fn` and `types.identified_message` create stable callback identities. Copies share their identity; separately constructed callbacks do not. Bare unidentified function messages bypass caching. Keep the callback deterministic for a given input/configuration.

See [CachedSchema](/api/methods--cachedschema-type/), [configuration](/guides/configuration/), and [errors](/guides/errors/).
