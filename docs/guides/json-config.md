# JSON parsing and serialization

`jsoncodec.decode` parses text with exact ties-to-even binary64 rounding for float tokens. Runtime-schema parse_text uses that same decoder. The optional ParseConfig can explicitly project all numeric tokens to binary64; default dynamic integer representation follows x.json2 and can still select f64.

```v
import math
import valibro.jsoncodec
import x.json2

value := jsoncodec.decode('1e23')!
assert math.f64_bits(value.f64()) == u64(4950912855330343670)
projected := jsoncodec.decode('9007199254740993', binary64_numbers:true)!
assert projected.f64() == 9007199254740992.0
assert jsoncodec.stringify(json2.Any(i64(9007199254740993)))! == '9007199254740993'
```

For exact large integers arriving as text, use JSON strings plus explicit BigInt conversion or a typed integer decoder. Comparison cannot recover digits already lost during decoding. Native integer serialization preserves its supplied value unless binary64 projection is explicitly selected.

## Formatting and native values

StringifyConfig supports integer or string indentation, explicit binary64 projection, and an optional positive traversal-depth guard. Ordinary output is UTF-8; map order follows the native map. Nonfinite floating values serialize as null, and signed zero is retained.

```v
import valibro as v
import valibro.jsoncodec
import x.json2

value := json2.Any({'name':json2.Any('Alex')})
assert jsoncodec.stringify(value, space:2)!.contains('\n  "name": "Alex"')
schema := v.pipe_to(v.number_of[i64](), v.stringify_json_value[i64]())
assert v.parse(schema, i64(9007199254740993))! == '9007199254740993'
parsed := v.pipe_to(v.string(), v.parse_json())
assert v.parse(parsed, '{"ready":true}')!.as_map().len == 1
```

Native serialization visits struct fields, arrays, maps, pointers, and V options directly. Struct fields honor V JSON tags, including skip, omitempty, required and json_null. Native time values preserve nanoseconds. Standard x.json2 encoder interfaces can supply an explicit representation. Convert BigInt or other domain values explicitly before encoding.

Transform or select properties in ordinary V code before serialization or after decoding. JSON conversion has no revivers, replacers, holder snapshots, property-list option, root-omission state, or deferred toJSON hooks.
