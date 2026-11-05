# Quick start

Start from a local checkout. These examples use `import valibro as v` and can run inside the repository with V 0.5.2 and its standard C toolchain.

## Run locally

```sh
v run examples/username
v run site
```

Open `http://127.0.0.1:8080`. The documentation server binds to the loopback interface. No package installation or publication is needed.

## Example

Combine a [string](/api/string/) schema with ordered actions using [pipe](/api/pipe/). Handle the result with [parse](/api/parse/).

```v
import valibro as v

username := v.pipe(v.string(), v.trim(), v.to_lower_case(),
    v.min_code_points(3, 'Use at least three characters'))
assert v.parse(username, ' Alex ')! == 'alex'
assert !v.is_valid(username, ' A ')!
```

## Match the native type

`v.number()` accepts `f64`. Numeric requirements need matching types: use `v.min_value(0.0)` with this schema.

```v
import valibro as v

age := v.pipe(v.number(), v.integer(), v.min_value(0.0), v.max_value(130.0))
assert v.parse(age, 42.0)! == 42.0
```

## Changing the output type

Use `pipe_to` when a transformation changes the output type. [pipe](/api/pipe/) composes actions that keep it.

```v
import valibro as v

schema := v.pipe_to(v.string(), v.to_number())
assert v.parse(schema, '42')! == 42.0
```
