# Presence and defaults

`types.Maybe[T]` explicitly distinguishes missing, undefined, null, and a value. It is separate from V's `?T` option type. Use the constructors rather than inferring presence from a zero value.

## Choose the wrapper

`optional` accepts missing and undefined; `exact_optional` accepts missing; `nullable` accepts null; `nullish` accepts missing, undefined, and null; `undefinedable` accepts undefined. Other states pass to the wrapped schema or fail according to the wrapper contract.

```v
import valibro as v
import valibro.types

schema := v.optional(v.pipe(v.string(), v.trim()), ' guest ')
assert v.parse(schema, types.missing[string]())!.value == 'guest'
assert v.parse(schema, types.some(' Alex '))!.value == 'Alex'
assert !v.safe_parse(schema, types.null_value[string]()).success
assert v.safe_parse(v.nullable(v.string()), types.null_value[string]()).success
assert !v.safe_parse(v.undefinedable(v.string()), types.missing[string]()).success
```

Defaults are inputs to the wrapped schema, so transformations also apply to them. `non_optional`, `non_nullable`, and `non_nullish` narrow accepted presence states. `unwrap` removes the wrapper; `unwrap_as` is fallible and verifies the requested native types.

## Computed defaults

`_with_default` callbacks receive the current config. `_with_default_context` variants also receive an optional dataset. `_with_default_state` returns `Maybe[I]` explicitly, so a provider can preserve a missing/null/undefined state instead of fabricating a value. Do not assume that an absent provider result means a literal default.

```v
import valibro as v
import valibro.types

schema := v.optional_with_default(v.string(), fn (config v.Config) string {
    return if config.lang == 'fr' { 'invité' } else { 'guest' }
})
result := v.safe_parse_with_config(schema, types.missing[string](), v.Config{lang: 'fr'})
assert result.success
assert result.output?.value == 'invité'
```

## Fallback output

A default handles an accepted absent input. A fallback replaces a failed validation's output. Fallback output is already type `O`; it is not revalidated through the wrapped schema. Runtime exceptions are not swallowed.

```v
import valibro as v

schema := v.fallback(v.pipe(v.string(), v.min_length(3)), 'anonymous')
assert v.parse(schema, 'x')! == 'anonymous'
assert v.get_fallback(schema)? == 'anonymous'
assert v.parse(v.unwrap(v.optional(v.string())), 'Alex')! == 'Alex'
```

`fallback_fn` computes from input and issues. `fallback_with_context` receives an optional output dataset and config. `get_default`, `get_fallback`, and context variants expose providers without inventing a dataset. Runtime JSON also provides recursive `get_defaults` and `get_fallbacks`; see [JSON schemas](/guides/json/).
