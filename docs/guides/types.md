# Types and lower-level APIs

Use the root module for ordinary parsing. `Schema[I, O]` stores a typed validation runner. `Action[T]` retains the output type, while `Transformation[I, O]` changes it. V's built-in result syntax is the public execution contract.

`Dataset[T]` is an advanced inspection and extension record: current value, typed state, accumulated issues, optional execution error, and optional boxed raw value. A typed dataset can have issues.

```v
import valibro as v
import valibro.types

schema := v.pipe(v.number_of[int](), v.min_value(0))
dataset := v.inspect(schema, -1)!
assert dataset.typed && dataset.issues.len == 1
boxed := types.value_of(42)
assert types.value_is[int](boxed)
assert types.value_as[int](boxed)! == 42
```

NativeValue retains a native type and value for heterogeneous partial outputs. RawArray, RawSet, RawMap, RawObject and RawStruct represent partial structures without claiming they are successful values of the declared output type. Obtain opaque values from their public factories.

Conversion-provider interfaces return native target values directly. Countable supplies a native collection count. PipelineRunner and contextual action/transformation constructors support advanced integrations. Applications own their native options, domain types, functions, concurrency, and serialization preprocessing.

Browse [native types](/api/types/), [schemas](/api/schemas/), [actions](/api/actions/), [execution methods](/api/methods/), and [JSON conversion](/guides/json-config/).
