# Installation

The VPM package is `alexvyber.valibro`; the repository is
[alexvyber/valibro](https://github.com/alexvyber/valibro). Version 0.0.0-dev.1 is prepared
locally; registry installation applies after registration.

Use V **0.5.2**, as recorded in `.v-version`, with its standard C toolchain.
The package requires no additional system libraries or package dependencies.
No handwritten C/C++ sources or direct C calls are shipped. Unicode 17 tables are included; URL, Date, regex and word segmentation use native
V implementations. No ICU installation, C++ compiler, parser download or bootstrap
command is needed.

macOS is locally verified; package CI is configured for macOS and Ubuntu using
the standard V setup. Windows installation is not verified.

## Install and use

```sh
v install alexvyber.valibro
```

Consumer imports use the publisher prefix:

```v
import alexvyber.valibro as v

fn main() {
    username := v.pipe(v.string(), v.trim(), v.min_length(3))
    assert v.parse(username, '  Alex  ') or { panic(err) } == 'Alex'
}
```

Submodules use `alexvyber.valibro.json`, `alexvyber.valibro.types`, etc. Declare
`dependencies: ['alexvyber.valibro']` in the application's `v.mod`. Repository
guides/examples use the checkout shorthand `import valibro as v`; replace its
prefix in installed consumer code.

Before registry publication, clone the source repository:

```sh
git clone https://github.com/alexvyber/valibro.git
cd valibro
v run examples/username
```

## Verify

```sh
v test .
v fmt -verify .
v run scripts/check_architecture.vsh
v run scripts/check_package.vsh
```

The package check copies a source-only snapshot into isolated `VMODULES` and
builds/runs a consumer importing `alexvyber.valibro` and submodules directly.
It requires Git to enumerate candidate source files. Ordinary tests use checked-in
fixtures offline and require neither Node nor Python.

See [native URL/Date behavior](native_url_date.md) and
[compatibility](compatibility.md) for the current contracts.
