# Metadata and brands

Metadata annotates a schema without validating input. Add titles, descriptions, examples, and metadata maps with `pipe`, then inspect them through getters.

## String annotations

```v
import valibro as v
import x.json2

schema := v.pipe(v.string(), v.title('Username'), v.description('Public account name'),
    v.examples(['alex']), v.metadata({'audience': json2.Any('public')}))
assert v.get_title(schema)? == 'Username'
assert v.get_description(schema)? == 'Public account name'
assert v.get_examples(schema)? == ['alex']
assert v.get_metadata(schema)['audience'].str() == 'public'
assert v.parse(schema, 'alex')! == 'alex'
```

Later named annotations override earlier values; metadata maps merge by key. Stored collections are copied where supported by the constructor. They are descriptive data, not extra validation requirements.

## Other native output types

Use `_for[T]` factories and `get_examples_for` for non-string outputs. `readonly_for[T]` follows V's native immutability model; it does not freeze a JavaScript object.

```v
import valibro as v

schema := v.pipe(v.number_of[int](), v.title_for[int]('Count'), v.examples_for[int]([1, 2, 3]))
assert v.get_title(schema)? == 'Count'
assert v.get_examples_for(schema)? == [1, 2, 3]
```

## Brands and flavors

`brand_for[T, B]` and `flavor_for[T, B]` transform a value into marker wrappers. Select a distinct native marker type `B` for each semantic role; unwrap the stored `.value` explicitly when needed.

```v
import valibro as v

struct UserId {}

fn main() {
    schema := v.pipe_to(v.number_of[int](), v.brand_for[int, UserId]())
    result := v.parse(schema, 42)!
    assert result.value == 42
}
```

See [annotations](/api/types--annotations-type/) and [root annotation factories](/api/).
