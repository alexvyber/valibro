# Native concurrency

Use V threads or channels around application work when concurrency is needed. Parsing itself uses native `!T` results, and callbacks can perform synchronous I/O. There is no library-owned scheduler or future type.

```v
import valibro as v

fn validate_name(name string) !string {
    return v.parse(v.pipe(v.string(), v.trim(), v.min_length(3)), name)
}

fn main() {
    assert validate_name(' Alex ')! == 'Alex'
}
```

Use [try_transform](/api/try_transform/) to compose native fallible functions, and ordinary typed functions to validate arguments or return values.
