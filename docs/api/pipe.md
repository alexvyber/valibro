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
result := v.inspect(schema, '  Alex_7  ')!
assert (result.issues.len == 0 && result.typed)
assert result.value == 'alex_7'
```


## Parameters

- `schema`: the starting schema, accepting input type `I` and producing output type `O`.
- `items`: zero or more checks, transformations, or metadata actions compatible with `O`.

## Returns

A new `types.Schema[I, O]`. The original schema remains reusable. The pipeline retains input type `I` and output type `O`; use `pipe_to` for transformations that change the output type.


## Failure behavior

By default, validation actions can collect multiple issues. A transformation encountered after an issue does not run; the pipeline stops there and marks the dataset untyped. Runtime exceptions stop execution and propagate according to the parsing method.

Set `abort_early` or `abort_pipe_early` through `parse with a trailing Config` to skip subsequent pipeline validations after an issue.

```v
import valibro as v

schema := v.pipe(v.string(), v.min_code_points(3), v.to_upper_case())
result := v.inspect(schema, 'ab')!
assert !(result.issues.len == 0 && result.typed)
assert !result.typed
assert result.issues.len > 0
assert result.issues.len == 1
```

## Reuse

Adding a pipeline does not modify its starting schema.

```v
import valibro as v

base := v.string()
required := v.pipe(base, v.min_code_points(1))
assert v.is_valid(base, '')!
assert !v.is_valid(required, '')!
```

## Related

- [string](/api/string/): create a string schema.
- [parse](/api/parse/): execute a pipeline.
- [Changing the output type](/guides/quick-start/#changing-the-output-type): use `pipe_to`.
