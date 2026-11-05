# Configuration and messages

A `types.Context` owns configuration and message maps. Assign context.config directly, and use methods on that context to manage scoped messages. There is no process-global configuration API.

## Scoped settings

Assign config on a mutable context and pass context.config explicitly to parsing. Reset it by assigning an empty Config. Languages select a message entry; they do not change string comparison, regex, or Unicode segmentation.

```v
import valibro as v
import valibro.types

mut context := types.Context{}
context.config = v.Config{abort_early: true}
settings := context.config
schema := v.pipe(v.string(), v.min_length(3), v.starts_with('a'))
assert v.inspect(schema, '', settings)!.issues.len == 1
context.config = v.Config{}
assert !context.config.abort_early
```

A schema wrapped with `config(schema, settings)` uses those captured settings rather than merging a later parse-call Config.

## Message precedence

A custom message supplied to a schema/action factory takes precedence. Otherwise config-level and scoped messages supply diagnostics according to their scope. Context methods manage issue-code, schema, and fallback messages. The language is an explicit string argument; an empty string selects the default language entry.

```v
import valibro as v

schema := v.pipe(v.string(), v.min_length(3, 'Use three characters'))
result := v.inspect(schema, 'x', v.Config{message: 'Invalid input'})!
assert result.issues[0].message == 'Use three characters'
callback := v.message_fn(fn (issue v.Issue) string {
    return 'Problem: ' + issue.code
})
custom := v.pipe(v.string(), v.min_length(3, callback))
assert v.inspect(custom, 'x')!.issues[0].message == 'Problem: min_length'
```

## Action overrides

`message` wraps an action with a chosen diagnostic. `message_fn` gives callback messages stable cache identity. Bare unidentified message functions can bypass caching; copies of an identified callback retain their identity.

```v
import valibro as v

schema := v.pipe(v.string(), v.message(v.min_length(3), 'Too short'))
assert v.inspect(schema, 'x')!.issues[0].message == 'Too short'
```

See [context storage helpers](/api/types--context-type/), [Config](/api/types--config-type/), and [caching](/guides/cache/).
