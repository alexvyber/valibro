# Errors and issue paths

`parse` returns a native error on validation failure. Its ValidationError contains structured issues. Execution errors from callbacks propagate unchanged through parse, inspect and is_valid.

```v
import valibro as v
import valibro.types

schema := v.pipe(v.string(), v.min_length(3))
if _ := v.parse(schema, 'x') { assert false } else {
    if err is types.ValidationError { assert err.issues.len == 1 } else { assert false }
}
```

## Structured diagnostics

Issues retain kind, code, message, expected/received descriptions, and typed path segments. get_dot_path formats a display path; flatten groups messages by path, and summarize formats a readable report.

```v
import valibro as v

schema := v.array(v.pipe(v.string(), v.min_length(3, 'Too short')))
result := v.inspect(schema, ['ok', 'valid'])!
assert result.issues.len == 1
assert v.get_dot_path(result.issues[0]) == '0'
assert v.flatten(result.issues).nested['0'] == ['Too short']
assert v.summarize(result.issues).contains('Too short')
```

## Partial values

Inspection exposes Dataset.value and optional raw_value for debugging failed transformations and partial collections. A typed dataset can still contain validation issues. Parse is the entry point for callers who need a validated value.

```v
import valibro as v
import valibro.types

result := v.inspect(v.pipe_to(v.schema[[]int](), v.to_number_from[[]int]()), [42])!
assert result.issues.len == 1
raw := result.raw_value or { panic('Expected original input') }
assert types.value_as[[]int](raw)! == [42]
```

Forward assigns new action issues to an existing field/key/index path. Missing paths retain their deepest existing prefix. Dot paths are display text; structured segments retain key/index identity. See [custom validation](/guides/custom/).
