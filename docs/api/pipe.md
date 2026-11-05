# pipe

Combines a schema with an ordered sequence of actions. Actions operate on the schema's output type.

## Signature

```v signature
fn pipe[I, O](schema types.Schema[I, O], items ...types.Action[O]) types.Schema[I, O]
```

Call it as `v.pipe(...)` through the root module. `types` refers to `valibro.types`.

## Example

Order matters: trim and lowercase the string before checking its content.

```v
import valibro as v

schema := v.pipe(v.string(), v.trim(), v.to_lower_case(),
    v.min_code_points(3), v.regex(r'^[a-z0-9_]+$'))
result := v.safe_parse(schema, '  Alex_7  ')
assert result.success
assert result.output? == 'alex_7'
```


## Parameters

- `schema`: the starting schema, accepting input type `I` and producing output type `O`.
- `items`: zero or more checks, transformations, or metadata actions compatible with `O`.

## Returns

A new `types.Schema[I, O]`. The original schema remains reusable. The pipeline retains input type `I` and output type `O`; use `pipe_to` for transformations that change the output type.


## Failure behavior

By default, validation actions can collect multiple issues. A transformation encountered after an issue does not run; the pipeline stops there and marks the dataset untyped. Runtime exceptions stop execution and propagate according to the parsing method.

Set `abort_early` or `abort_pipe_early` through `safe_parse_with_config` to skip subsequent pipeline validations after an issue.

```v
import valibro as v

schema := v.pipe(v.string(), v.min_code_points(3), v.to_upper_case())
result := v.safe_parse(schema, 'ab')
assert !result.success
assert !result.typed
assert result.output == none
assert result.issues.len == 1
```

## Reuse

Adding a pipeline does not modify its starting schema.

```v
import valibro as v

base := v.string()
required := v.pipe(base, v.min_code_points(1))
assert v.safe_parse(base, '').success
assert !v.safe_parse(required, '').success
```

## Related

- [string](/api/string/): create a string schema.
- [safe_parse](/api/safe_parse/): execute a pipeline.
- [Changing the output type](/guides/quick-start/#changing-the-output-type): use `pipe_to`.
