# Unicode and word segmentation

The core uses versioned **Unicode 17.0.0** data and pure V algorithms. Tables are bundled; no external Unicode library is linked.
Native strings must contain valid UTF-8. Date parsing accepts native text.
Ordinary JSON output and diagnostics stay UTF-8; explicit UTF-16 output/accessors
convert on demand for interoperability.

## Core actions

- `normalize()` uses NFC; `.nfd`, `.nfkc`, and `.nfkd` select other forms.
- `to_lower_case` and `to_upper_case` use full default mappings, including
  expansions and final-sigma context. These are not locale-specific mappings.
- `graphemes`, `min_graphemes`, `max_graphemes`, and `not_graphemes` use extended
  grapheme clusters, including emoji and Indic conjunct rules.
- `emoji` validates the pinned upstream property-based sequence grammar.
- `bytes` counts UTF-8 bytes; `length` and `code_points`
  count Unicode scalar values; each has minimum/maximum/exclusion variants.

For example, `🙂` occupies four UTF-8 bytes, one code point,
and one grapheme. `Straße` uppercases to `STRASSE`, `ﬁ` to `FI`, and `ΟΣ`
lowercases to `ος`. Default lowercase of `İ` includes a combining dot.

Camel/Pascal/kebab/snake transformations use the reference separator, acronym,
and digit boundaries with full Unicode casing. They are not linguistic word
segmenters.

## Native word counts

`words`, `min_words`, `max_words`, and `not_words` use Unicode 17 default
UAX #29 boundaries. A segment counts as a word if it contains at least one
Unicode letter or number (general categories L or N). Punctuation, standalone
combining marks, whitespace and emoji-only segments do not count. Input must
be valid UTF-8. `unicode.word_count` exposes the same counter;
`unicode.word_boundaries` returns rune indices, including the start and end.

Examples: `don't stop!` counts 2; `a_b 123.45` counts 2; `🙂 👩🏽‍💻` counts 0.
There is no locale or dictionary tailoring. `ภาษาไทย` counts 7,
`東京に行きます` counts 7, and `你好世界` counts 4. These default boundaries
can differ from Valibot's `Intl.Segmenter` linguistic word counts.

The locale-selecting `words_in`, `min_words_in`, `max_words_in`, and
`not_words_in` factories have been removed. Migrate to the corresponding
factory without `_in` and remove the locale argument. Applications requiring
linguistic segmentation can supply their own counter through a custom check.

The `valibro.icu` module, including `RegexConfig`, `regex`, and
`regex_with_config`, has been removed. Use `v.regex`, `v.regex_with_flags`,
`v.compile_regex` or `v.regex_object` within the documented native V regex
subset; ICU-specific pattern syntax requires rewriting. See [strings](string_api.md).

## Source data and verification

`unicode/SOURCES.json` pins the Unicode source files and SHA-256 hashes;
`unicode/LICENSE` contains their license. `tools/unicode/generate_tables.py` rebuilds
tables and copies official conformance fixtures from a flattened UCD directory.
Normal builds and tests need no Python or Node.

Tests include every listed Unicode 17 normalization, grapheme-break, and
word-break conformance case, 15,679 casing/emoji inputs, 4,858 contextual
case-formatting inputs, and native word-count/action cases. String content
failures compare whole-code-point fragments and explicit UTF-16 accessors. `Issue.received_units()` and
`Issue.message_units()` encode their native UTF-8 strings on demand. Ordinary
diagnostics never split surrogate pairs.

See [compatibility](compatibility.md) for the complete runtime model and evidence.
