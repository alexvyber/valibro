# Parsing and pipelines

[pipe](/api/pipe/) runs a schema followed by same-output-type actions. `pipe_to` adds a type-changing transformation. Schemas are immutable and reusable.

## Parsing choices

`parse` returns `!O`, using a `ValidationError` for ordinary validation failure. `safe_parse` returns a result with `success`, `typed`, `issues`, `raw_output`, and success-only optional `output`. `is_valid` returns a boolean; `assert_valid` returns a fallible void result. Runtime exceptions still propagate or panic according to the chosen entry point.

```v
import valibro as v

schema := v.pipe(v.string(), v.trim(), v.min_length(2))
assert v.parse(schema, ' Alex ')! == 'Alex'
assert v.is_valid(schema, 'Alex')
v.assert_valid(schema, 'Alex')!
parser := v.parser(schema)
assert parser(' Alex ')! == 'Alex'
safe_parser := v.safe_parser(schema)
assert !safe_parser('x').success
```

## Configuration and stopping

`config` binds settings to a schema and ignores settings passed later when that configured wrapper runs. `_with_config` parsing functions provide settings for schemas that do not already bind their own configuration. `abort_early` stops after the first issue; `abort_pipe_early` skips later validations in that pipeline. Without these settings, consecutive validations can collect issues.

A transformation after any validation issue does not run and the pipeline stops at that boundary. An exception stops execution independently of issue collection.

```v
import valibro as v

schema := v.pipe(v.string(), v.min_length(3), v.starts_with('a'))
assert v.safe_parse(schema, '').issues.len == 2
assert v.safe_parse_with_config(schema, '', v.Config{abort_pipe_early: true}).issues.len == 1
configured := v.config(schema, v.Config{abort_early: true})
assert v.safe_parse(configured, '').issues.len == 1
```

## Checked parsing

`safe_parse_checked` is the fallible form for catching runtime exceptions while retaining structured validation failures. Nonfallible `safe_parse` panics on an exception. Native callback errors are not JavaScript exceptions or ordinary issues.

```v
import valibro as v

result := v.safe_parse_checked(v.pipe(v.number(), v.integer()), 1.5)!
assert !result.success
assert result.typed
assert result.output == none
```

See [errors](/guides/errors/), [configuration](/guides/configuration/), and [async execution](/guides/async/).
