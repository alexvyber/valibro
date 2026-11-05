# Async and functions

Native callbacks can perform I/O directly. Async parsing adapters move a complete parse onto a V worker; they do not simulate a JavaScript event loop.

## Channels and futures

`safe_parse_async` returns a buffered channel containing a structured result. Check `exception` before using a result that may contain a runtime error. `parse_async` returns `types.Future[O]`, whose fallible `await` can be called repeatedly.

```v
import valibro as v

schema := v.pipe(v.string(), v.trim())
channel := v.safe_parse_async(schema, ' Alex ')
result := <-channel
assert result.exception == none
assert result.success
assert result.output? == 'Alex'
future := v.parse_async(schema, ' Alex ')
assert future.await()! == 'Alex'
assert future.await()! == 'Alex'
```

`parser_async` returns a reusable future-producing function. `safe_parser_async` returns a channel-producing function. `promise[T]` validates a native future container; `await_future[T]` unwraps it through a type-changing pipeline. `_with_config` variants pass settings to the worker.

## Function contracts

`types.Function[I, O]` holds a native function. `function_schema` validates the container. `args` validates and transforms each call's input, producing a `FallibleFunction` so invalid arguments can return a validation error.

```v
import valibro as v
import valibro.types

schema := v.pipe_to(v.function_schema[string, string](),
    v.args[string, string, string](v.pipe(v.string(), v.trim(), v.min_length(2))))
function := v.parse(schema, types.Function[string, string]{call: fn (text string) string {
    return text + '!'
}})!
assert function.call(' Alex ')! == 'Alex!'
```

## Return validation

`returns` validates outputs of ordinary native functions. `returns_checked` composes with an already-fallible function, including one produced by `args`. Use an explicit wrapper to validate arguments of an already-fallible callable. Callback errors remain native runtime errors; they are not rewritten as ordinary validation issues.

```v
import valibro as v
import valibro.types

schema := v.pipe_to(v.function_schema[string, f64](),
    v.returns[string, f64, f64](v.pipe(v.number(), v.integer())))
function := v.parse(schema, types.Function[string, f64]{call: fn (text string) f64 {
    return text.f64()
}})!
assert function.call('42')! == 42.0
```

See [Future](/api/types--future-type/), [Function](/api/types--function-type/), and [parsing](/guides/execution/).
