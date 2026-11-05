# Configuration and messages

A `types.Context` owns configuration and message maps. The functions named `set_global_*` operate on the context you pass; they do not mutate process-wide state.

## Scoped settings

Set config on a mutable context, retrieve it, and pass it explicitly to parsing. Delete helpers remove the matching scoped setting. Languages select a message entry; they do not change string comparison, regex, or Unicode segmentation.

```v
import valibro as v
import valibro.types

mut context := types.Context{}
v.set_global_config(mut context, v.Config{abort_early: true})
settings := v.get_global_config(context)
schema := v.pipe(v.string(), v.min_length(3), v.starts_with('a'))
assert v.safe_parse_with_config(schema, '', settings).issues.len == 1
v.delete_global_config(mut context)
assert !v.get_global_config(context).abort_early
```

A schema wrapped with `config(schema, settings)` uses those captured settings rather than merging a later parse-call Config.

## Message precedence

A custom message supplied to a schema/action factory takes precedence. Otherwise config-level and scoped messages supply diagnostics according to their scope. Specific action messages, schema messages, and global messages have distinct setters/getters/deleters, with optional language selection.

```v
import valibro as v

schema := v.pipe(v.string(), v.min_length(3, 'Use three characters'))
result := v.safe_parse_with_config(schema, 'x', v.Config{message: 'Invalid input'})
assert result.issues[0].message == 'Use three characters'
callback := v.message_fn(fn (issue v.Issue) string {
    return 'Problem: ' + issue.code
})
custom := v.pipe(v.string(), v.min_length(3, callback))
assert v.safe_parse(custom, 'x').issues[0].message == 'Problem: min_length'
```

## Action overrides

`message` wraps an action with a chosen diagnostic. `message_fn` gives callback messages stable cache identity. Bare unidentified message functions can bypass caching; copies of an identified callback retain their identity.

```v
import valibro as v

schema := v.pipe(v.string(), v.message(v.min_length(3), 'Too short'))
assert v.safe_parse(schema, 'x').issues[0].message == 'Too short'
```

See [context storage helpers](/api/storages/), [Config](/api/types--config-type/), and [caching](/guides/cache/).
