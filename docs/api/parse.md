# parse

Validate and transform input, returning a value or a native V error.

## Signature

```v signature
fn parse[I, O](schema types.Schema[I, O], input I, config types.Config) !O
```

## Example

```v
import valibro as v
import valibro.types

schema := v.pipe(v.string(), v.trim(), v.min_length(3))
assert v.parse(schema, ' Alex ')! == 'Alex'
if _ := v.parse(schema, 'x') {
    assert false
} else {
    assert err is types.ValidationError
}
```

ValidationError contains the collected issues. Callback errors propagate unchanged. The optional trailing Config uses V parameter structs, so `v.parse(schema, input, abort_early: true)` selects early abort without a separate parsing function.

Use [inspection](/api/inspect/) for validation issues and partial values. A dataset with issues never constitutes a successful parsed value.
