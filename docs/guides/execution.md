# Parsing and pipelines

`parse` returns `!O`: V requires an error handler or propagation. ValidationError retains the collected issues. `is_valid` returns `!bool`, returning false for rejection and propagating execution errors. Both accept an optional trailing Config parameter struct.

```v
import valibro as v
import valibro.types

schema := v.pipe(v.string(), v.trim(), v.min_length(3))
assert v.parse(schema, ' Alex ')! == 'Alex'
assert !v.is_valid(schema, 'x')!
if _ := v.parse(schema, 'x') { assert false } else { assert err is types.ValidationError }
```

## Inspection

`inspect` returns `!Dataset[O]` for advanced diagnostics. It returns validation issues and partial values; execution errors still propagate. A typed dataset can have validation issues. Read a successful value through parse when failure output is not needed.

```v
import valibro as v
import valibro.types

schema := v.pipe(v.string(), v.min_length(3), v.ends_with('z'))
result := v.inspect(schema, 'a')!
assert result.issues.len == 2
assert result.typed
assert result.value == 'a'
assert v.inspect(schema, 'a', abort_early: true)!.issues.len == 1
```

## Concurrency

Applications choose V threads and channels. A validation callback can perform synchronous I/O and return a native error through try_transform. Valibro has no futures, promises, async parsing aliases, or callable containers. See [custom validation](/guides/custom/).

Pipelines reuse immutable schema definitions. Actions run in order; consecutive validations can collect issues. A transformation does not run after validation failure. A schema bound with config uses the captured settings.
