# Typed objects

Native structs use `object`, `field`, and `object_from`. V does not offer JavaScript-style dynamic property mutation; fields use explicit getter and setter callbacks.

## Validate and transform fields

A field carries its name, getter, setter, and nested schema. The name becomes part of the issue path. Setters return a new struct value.

```v
import valibro as v

struct User {
    name string
}

fn main() {
    schema := v.object[User](v.field('name', fn (user User) string {
        return user.name
    }, fn (user User, name string) User {
        return User{...user, name: name}
    }, v.pipe(v.string(), v.trim(), v.min_length(2))))
    assert v.parse(schema, User{name: ' Alex '})!.name == 'Alex'
    invalid := v.safe_parse(schema, User{name: 'x'})
    assert !invalid.success
    assert v.get_dot_path(invalid.issues[0]) == 'name'
}
```

## Different output structs

`object_from[I, O]` starts with an initializer from input to output, then applies `Field[I, O]` mappings. Use `field[P, Q, I, O]` with explicit generic arguments when the compiler cannot infer both parent types.

The initializer determines untouched output fields. Field schemas can change their value types through `pipe_to`. An invalid field does not produce success-only typed output; inspect issues and the raw dataset instead.

## Shape operations

Dynamic `pick`, `omit`, `partial`, `required`, `keyof`, strict objects, loose objects, and objects with a rest schema belong to [runtime JSON schemas](/guides/json/). Native struct fields are fixed at compile time.

For cross-field checks, use [partial_check](/api/partial_check/) with paths that select the dependencies of the predicate. See [custom validation](/guides/custom/).
