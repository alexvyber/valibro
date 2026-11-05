# Local documentation site

A native V documentation application, with plain HTML and CSS. It uses V templates,
`net.http` for the local server, `v.scanner` for syntax highlighting, and `x.json2`
for checking `v doc` output. It has no
VPM dependencies, browser JavaScript, external fonts, Markdown C bindings, or build
steps requiring another language. Run commands from the repository root with V 0.5.2.

```sh
v run site                         # http://127.0.0.1:8080
v run site serve 8081              # choose a local port
v run site check                   # full API coverage, links, executable examples
v run site inventory               # refresh public declarations from V sources
v run site audit                   # reject missing semantic descriptions
v test site                       # renderer, HTTP handlers, search, static export
v run site build                   # export to ignored site/public/
v run site build /tmp/valibro-docs # choose an output directory
```

The server binds to `127.0.0.1`. It reads content at startup; restart it after edits.
The compiled binary records the source checkout location, so keep that checkout
available when running it. Static exports are independent of the checkout.
No command deploys anything, registers a VPM package, or pushes Git changes.

## Content and navigation

Author guides in `docs/guides/` and register their title and summary in
`site/reference.v`. The original detailed `string`, `pipe`, and `safe_parse` pages
remain in `docs/api/`. Other reference pages and all module indexes are rendered
from `site/reference.json`, generated using `v doc -f json`. Their signatures,
source comments, file locations, and receiver methods come from the V source.
Reference summaries are selected by API semantics in `site/descriptions.v` and
`site/format_docs.v`, with namespace-specific distinctions for constructors,
schemas, adapters, and receivers. Missing summaries fail the build. Useful
behavior notes are explicit; parameter-list types are not used to guess whether
a function is a schema/action factory.

Reference pages embed matching executable examples from the authored guides and
`docs/examples/*.vv`, plus small format/measurement examples. Implementation-module
pages label examples that use the root convenience API. Every public declaration must have an inline executable example. Opaque types
use their public factories, and aliases may demonstrate the canonical underlying
type. Namespace and receiver checks prevent substituting an unrelated same-named
API. Family guides provide additional context rather than satisfying example
coverage by themselves.
This is generated declaration coverage plus family-level usage documentation;
it is not a claim that every overload has its own authored tutorial.

The inventory covers all public declarations exposed by `v doc` in the root,
`schemas`, `actions`, `methods`, `types`, `json`, `jsoncodec`, `storages`, and
`unicode` modules. It includes generic receiver methods below synthetic parent
nodes, aliases, interfaces, and constants. `internal` modules are excluded by the
package's ownership convention. V-generated public enum conversion methods are
included when reported by the pinned compiler.

Run `v run site inventory` after changing public declarations or their source
comments. `check` regenerates inventory in a temporary directory and compares it
without modifying the checked-in snapshot. It also checks complete reference
coverage, declaration text, unique URLs, example-guide links, and internal
links/anchors. The inventory contains no absolute checkout paths or timestamps.

Navigation lists guides and module indexes; each index links to all its members.
The current API entry remains visible in the sidebar. Root-relative URLs assume
the site is served at a host's root.

The native Markdown renderer intentionally supports a small subset:

- Paragraphs, inline code, links, and flat unordered lists.
- Headings at levels 1–3, with stable anchors and duplicate-anchor suffixes.
- Fenced `v`, `v signature`, `sh`, and `text` code blocks.

HTML is escaped. Tables, images, emphasis, nested lists, and other Markdown syntax
are not implemented. Keep authored pages within this subset. No raw HTML is
needed for documentation content. Allowed link targets are local absolute paths,
page anchors, and HTTPS URLs.

Every `v` fence must be a standalone executable example. `check` creates temporary
files under ignored `site/.checks-<pid>/`, runs them, and removes them afterward. Use
`v signature` fences for highlighted signatures that cannot run on their own, and
`text` fences for plain fragments. Signatures are excluded from executable examples.
Repeated example programs are compiled and executed once per check, even when
shown on several pages. The check reports both unique programs and placements.
Every standalone program in `docs/examples/*.vv` is also verified. A single
compiler/example process runs at a time to bound memory for generic-heavy V
programs, with a separate temporary directory for each example. Example compilation
uses V’s `-no-parallel` code-generation option; an intermittent missing-generic
code-generation failure was observed with parallel generation in the pinned V
0.5.2 toolchain during this audit. The checker disables automatic V compiler
bug-report uploads for its subprocesses, keeping failure diagnostics local.
`v doc -f json` supplies source signatures for checking documented API functions.
Every public declaration must have one reference page and an inline executable
example. Link checks cover generated and
authored internal links and their target anchors; external websites are not fetched.

## Rendering and search

The layout uses responsive CSS, the system light/dark preference, a collapsible
mobile menu, a skip link, and visible focus indicators. It requires no browser
scripts. V examples and signatures are highlighted using `v.scanner` tokens and
CSS classes, with light/dark token colors following the system theme. Whitespace,
quotes, Unicode, and interpolation are preserved from the original source. This
is lexical highlighting, with naming/context heuristics for functions and types;
it does not perform semantic type checking. Lexer errors fall back to escaped
plain text. Shell commands and `text` blocks remain escaped plain text.

Local search uses a GET form and a V handler. All search words must occur in a
page's title, summary, or Markdown source, case-insensitively. Exact root API
names rank first; results are limited to 50. The HTML response escapes the query. The static export has a complete page index at `/search/` instead of live
search. Both modes expose individual Markdown files; the static export also
includes `/llms.txt` and `404.html`.

Keep the site implementation independent of runtime library modules. Its tests
exercise the docs application; the package's own tests cover library behavior.

## Presentation and themes

Every page uses the shared handbook layout: warm paper and ink in light mode,
blue-black surfaces in dark mode, locally hosted IBM Plex Sans/Mono, blue accents,
numbered navigation, and flat code panels. Guides, public API pages, module
indexes, search, and 404 pages share the same V template and stylesheet.

Navigation expands the active category or implementation module. API indexes
use compact symbol/description rows, and signatures wrap without changing their
copyable text. Examples preserve their source formatting and scroll as needed;
keyboard users can focus code blocks. Native HTML details controls expose mobile
navigation and the current page contents separately.

On the local V server, `?theme=light` and `?theme=dark` override the system theme
on any page. The Light/Dark links preserve the current page and search query;
internal navigation and search forms carry the selected theme. Without an
override, the site follows the system preference. No browser scripts, cookies,
or browser storage are used. Static exports use the system preference; explicit
query-string overrides require the V server.

IBM Plex assets under `assets/fonts/` are served through a fixed allowlist and
copied into static exports with their OFL license and provenance. Builds and
normal use do not contact a font service or require additional tools.

Presentation tests cover shared layouts, complete API indexes, navigation links,
scoped theme handling, static assets, search forms, and token contrast in both
palettes. Browser checks exercise desktop and mobile layouts and native menus.
