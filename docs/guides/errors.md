# Errors and issue paths

A validation issue explains an invalid value. A runtime exception means execution failed. `safe_parse_checked` distinguishes them: ordinary issues are in the returned result, while runtime exceptions use V's error result.

## Structured diagnostics

An `Issue` includes `kind`, `code`, `message`, expected/received descriptions, and path segments. `get_dot_path` formats representable paths; `flatten` groups root, nested, and other messages. `summarize` formats a readable report. Not every arbitrary-key path has a dot representation.

```v
import valibro as v

schema := v.array(v.pipe(v.string(), v.min_length(3, 'Too short')))
result := v.safe_parse(schema, ['ok', 'valid'])
assert !result.success
assert v.get_dot_path(result.issues[0]) == '0'
assert v.flatten(result.issues).nested['0'] == ['Too short']
assert v.summarize(result.issues).contains('Too short')
```

## Failure output

`.output` is absent on validation failure. `.raw_output` retains a boxed dataset value, including partial structures and original values for failed conversions. `typed` can remain true after a check failure; use `success` to decide whether validation succeeded.

```v
import valibro as v
import valibro.types

result := v.safe_parse(v.pipe(v.string(), v.min_length(3)), 'ab')
assert !result.success
assert result.typed
assert result.output == none
assert types.value_as[string](result.raw_output)! == 'ab'
```

## Fallible parsing

A failed `parse` returns an inspectable `types.ValidationError`. Use `is_vali_error` when handling an `IError`; range and type errors are separate native errors. UTF-16 message/received accessors convert on demand and are only needed for interoperability.

```v
import valibro as v
import valibro.types

fn main() {
    v.parse(v.pipe(v.string(), v.min_length(3)), 'x') or {
        assert v.is_vali_error(err)
        if err is types.ValidationError {
            assert err.issues.len == 1
        }
        return
    }
    panic('Expected a validation error')
}
```

## Forwarding paths

`forward` assigns an action's issues to a selected existing path. Array paths use integer indexes and object paths use actual field/map keys. Missing paths retain the deepest existing prefix. This performs native structural lookup without JavaScript property emulation.

See [custom validation](/guides/custom/) for cross-field dependencies and [types](/api/types/) for full issue declarations.
