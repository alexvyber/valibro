# JSON parsing and serialization

The `jsoncodec` module controls JSON text conversion. Root actions expose these operations through typed pipelines. These are native JSON APIs, with explicit callbacks and supported value types.

## Parse and stringify

> Precision: dynamic JSON parsing can select `f64` for integer tokens. Use a JSON string and explicit BigInt conversion when large input integers must remain exact.

Float decoding uses exact ties-to-even rounding. `binary64_numbers` explicitly forces floating-number projection; disabling it does not guarantee an integer alternative. Serialization of explicitly supplied native integers retains precision unless binary64 projection is requested.

```v
import valibro.jsoncodec
import x.json2

parsed := jsoncodec.decode('{"n":42}')!
object := parsed.as_map()
assert (object['n'] or { panic('n') }).f64() == 42.0
native := json2.Any({'n': json2.Any(i64(9007199254740993))})
output := jsoncodec.stringify(native, jsoncodec.StringifyConfig{})!
assert output.contains('9007199254740993')
```

For exact large integers arriving as text, encode the decimal digits as a JSON string and convert explicitly with `to_bigint`, or use a typed integer decoder with an explicit range policy. Do not rely on dynamic number decoding to retain those digits.

```v
import valibro as v
import valibro.json as j

text := j.parse_text(j.string(), '"9007199254740993"')!.str()
integer := v.parse(v.pipe_to(v.string(), v.to_bigint()), text)!
assert integer.str() == '9007199254740993'
```

## Reviver callbacks

A parse reviver receives key, value, and a context. Primitive source text is available when provided by the decoder, while `holder` is a native snapshot of the containing object/array. Return a `Maybe[json2.Any]` to retain, replace, or omit a value. Callback errors remain fallible errors.

```v
import valibro.jsoncodec
import valibro.types
import x.json2

config := jsoncodec.ParseConfig{reviver: fn (key string, value json2.Any, context jsoncodec.ReviverContext) !types.Maybe[json2.Any] {
    if key == 'secret' { return types.undefined_value[json2.Any]() }
    return types.some[json2.Any](value)
}}
result := jsoncodec.parse('{"name":"Alex","secret":"hidden"}', config)!
assert result.state == .value
assert 'secret' !in result.value.as_map()
```

## Replacers and output policy

`StringifyConfig` supports plain, contextual, and presence-aware replacers. Presence-aware callbacks take precedence, then contextual callbacks. `property_list` selects properties; an absent list preserves native map iteration order, and an empty list selects no object properties. `space` controls indentation. `max_depth` can bound traversal; zero leaves it unbounded.

```v
import valibro.jsoncodec

value := jsoncodec.decode('{"name":"Alex","secret":"hidden"}')!
output := jsoncodec.stringify(value, jsoncodec.StringifyConfig{property_list: ['name'], space: 2})!
assert output.contains('"name": "Alex"')
assert !output.contains('secret')
```

## Pipelines and native values

`parse_json` changes string input into `json2.Any`. Configured parsing can return `Maybe[json2.Any]` when a callback removes the root. `stringify_json_value[T]` handles native values; `stringify_json_with_config` handles JSON values. Explicit UTF-16 functions exist for interoperability; ordinary output stays UTF-8.

```v
import valibro as v

schema := v.pipe_to(v.string(), v.parse_json())
parsed := v.parse(schema, '{"ready":true}')!
assert parsed.as_map().len == 1
stringify := v.pipe_to(v.number_of[int](), v.stringify_json_value[int]())
assert v.parse(stringify, 42)! == '42'
```

`JsonValueProvider` and `JsonSource` expose explicit native serialization hooks. Native sets/maps/blobs/files serialize their declared containers and fields. Functions and futures require explicit JSON hooks or awaiting; do not assume browser object serialization or implicit array-to-string coercion. See [jsoncodec reference](/api/jsoncodec/).
