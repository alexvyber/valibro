# safe_parse

Runs a schema and returns a structured validation result. Ordinary validation failures are returned as issues.

## Signature

```v signature
fn safe_parse[I, O](schema types.Schema[I, O], input I) types.SafeParseResult[O]
```

Call it as `v.safe_parse(...)` through the root module. `types` refers to `valibro.types`.

## Example

```v
import valibro as v

schema := v.pipe(v.string(), v.trim(), v.min_code_points(3))
result := v.safe_parse(schema, '  Alex  ')
if result.success {
    output := result.output or { panic('Successful result must have output') }
    assert output == 'Alex'
} else {
    for issue in result.issues {
        println('${issue.code}: ${issue.message}')
    }
}
```


## Parameters

- `schema`: a schema accepting input type `I` and producing output type `O`.
- `input`: a native V value matching the schema's input type.

## Returns

`types.SafeParseResult[O]` contains these fields:

- `success`: true when parsing completes without validation issues.
- `typed`: whether the final dataset retains its schema's typed state. This can be true even when a validation check fails.
- `output`: an optional `O`, present only on success.
- `issues`: structured validation issues, empty on success.
- `raw_output`: a boxed view of the resulting value, including partial output on failure.
- `exception`: an optional runtime exception field. This entry point does not return runtime exceptions in the field; it panics instead.

Use `success` to decide whether parsing succeeded. Do not use `typed` as a success flag.


## Validation failures

A failed check leaves the success-only typed output absent. Inspect `issues` for diagnostics and `raw_output` when you need the failure dataset's value.

```v
import valibro as v

schema := v.pipe(v.string(), v.min_code_points(3, 'Too short'))
result := v.safe_parse(schema, 'ab')
assert !result.success
assert result.typed
assert result.output == none
assert result.issues.len == 1
assert result.issues[0].message == 'Too short'
```

## Runtime exceptions

Callback errors and other runtime exceptions are distinct from validation issues. `safe_parse` panics on a runtime exception. Use `safe_parse_checked` for a fallible result, and handle its `!` error with V's normal error handling.

```v
import valibro as v

result := v.safe_parse_checked(v.string(), 'hello') or { panic(err) }
assert result.success
assert result.output? == 'hello'
```

## Configuration

Use `safe_parse_with_config` to pass validation settings explicitly. The native V result semantics remain the same.

```v
import valibro as v
import valibro.types

schema := v.pipe(v.string(), v.min_code_points(3), v.starts_with('a'))
result := v.safe_parse_with_config(schema, '', types.Config{abort_early: true})
assert !result.success
assert result.issues.len == 1
```

## Related

- [string](/api/string/): validate UTF-8 input.
- [pipe](/api/pipe/): build a sequence of actions.
- [Quick start](/guides/quick-start/): combine schemas, transformations, and checks.
