# Valibro

Composable validation for native V values and runtime JSON. Valibro uses the standard V toolchain, with no external VPM dependencies. Tested with V 0.5.2.

## Quick start

```v
import valibro as v

schema := v.pipe(v.string(), v.trim(), v.to_lower_case(), v.min_length(3))
name := v.parse(schema, ' Alex ') or { eprintln(err); return }
println(name) // alex
```

Parse returns a native `!T`. ValidationError retains structured issues. Inspect returns `!Dataset[T]` for advanced partial-value inspection. Is_valid returns `!bool`: validation rejection is false and callback errors propagate.

```v
import valibro as v

age := v.pipe(v.number_of[int](), v.min_value(0), v.max_value(130))
assert v.parse(age, 42)! == 42
assert !v.is_valid(age, -1)!
assert v.inspect(age, -1)!.issues.len == 1
```

Native options are handled with ordinary V if/or expressions. Native functions and threads belong to the application. Runtime JSON supports missing-field and explicit-null policies through optional and nullable; there is no undefined value model or JavaScript callback protocol.

Exact decimal/radix conversion rounds once to binary64 using ties-to-even. Native integer equality and serialization preserve supplied digits. Runtime JSON object schemas reject arrays. UTF-8 strings, native regex, strict calendar validation and bundled Unicode 17 algorithms retain their documented contracts.

## Installation

The VPM package name is `alexvyber.valibro`. Use `import alexvyber.valibro as v` in consumers, or `import valibro as v` inside a checkout. See [installation](docs/install.md) and [release preparation](docs/releasing.md).

## Documentation

Run `V_C_ERROR_BUG_REPORT_DISABLED=1 v run site` for a local native HTTP preview, or `v run site build` for static export. See [site development](site/README.md), [native API migration](docs/native_api_migration.md), [numeric behavior](docs/native_behavior.md), and the [API inventory](site/reference.json).

## Validation

```sh
V_C_ERROR_BUG_REPORT_DISABLED=1 VJOBS=1 v -no-parallel test .
V_C_ERROR_BUG_REPORT_DISABLED=1 v fmt -verify .
V_C_ERROR_BUG_REPORT_DISABLED=1 v run scripts/check_architecture.vsh
V_C_ERROR_BUG_REPORT_DISABLED=1 v run scripts/check_package.vsh
V_C_ERROR_BUG_REPORT_DISABLED=1 v run site check
```

The compiler diagnostic-upload flag should be set for all V invocations. The checked-in rounding and Unicode/reference data run offline. Maintainer reference generators are separate from the native package and documentation runtime.
