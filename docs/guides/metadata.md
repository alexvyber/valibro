# Schema metadata

Titles, descriptions, examples, and metadata describe a schema without validating its value. Metadata survives pipeline composition; later entries override matching earlier entries. Native domain types belong to application-defined V aliases or structs.

```v
import valibro as v
import x.json2

schema := v.pipe(v.string(), v.title[string]('Name'), v.description[string]('Display name'),
    v.examples(['Alex']), v.metadata[string]({'private':json2.Any(false)}))
assert v.get_title(schema)? == 'Name'
assert v.get_description(schema)? == 'Display name'
assert v.get_examples(schema)? == ['Alex']
assert v.get_metadata(schema)['private']! == json2.Any(false)
number := v.pipe(v.number_of[int](), v.title[int]('Count'),
    v.description[int]('Item count'), v.examples[int]([1, 2]),
    v.metadata[int]({'unit':json2.Any('items')}))
assert v.get_examples(number)? == [1,2]
```

V controls mutability and native type identity. Valibro does not expose readonly actions, brands, flavors, symbols, or runtime instance schemas.
