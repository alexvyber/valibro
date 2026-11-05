# Introduction

Validate native V values with small, composable schemas. Add checks and transformations, then handle the result with typed output and structured errors.

## Start with a schema

A schema describes the input it accepts and the output it produces. Add actions with [pipe](/api/pipe/), then inspect the result with [parse](/api/parse/).

```v
import valibro as v

username := v.pipe(v.string(), v.trim(), v.min_code_points(3))
result := v.inspect(username, '  Alex  ')!
assert (result.issues.len == 0 && result.typed)
assert result.value == 'Alex'
```

## Two ways to validate

Native schemas work with statically typed V inputs. The [string](/api/string/) schema takes a string; passing an integer is a compile-time error.

The separate `valibro.json` module handles unknown JSON values and heterogeneous structures. Choose it when the input shape is only known at runtime.

## Native by design

Valibro uses native V behavior for numbers, regular expressions, URLs, and dates. String schemas require well-formed UTF-8. The package needs the standard V toolchain, with no additional parser engines or system libraries.

This documentation describes the V API directly. Names and behavior can differ from Valibot where the languages have different value models.

## Where to go next

- [Quick start](/guides/quick-start/): run the package locally and build a validation pipeline.
- [string](/api/string/): validate UTF-8 input.
- [pipe](/api/pipe/): order checks and transformations.
- [parse](/api/parse/): handle output and validation issues.

For now, start from a local checkout; the package and documentation site are unpublished.
