# Unicode

Valibro bundles Unicode 17.0.0 tables and uses native V algorithms. No ICU library is needed. Native string schemas reject malformed UTF-8 before Unicode actions run.

## Measure explicitly

Bytes count UTF-8 storage, code points count scalar values, and graphemes count extended grapheme clusters. String `length` uses code points. Each measurement action has minimum, maximum, and exclusion variants.

```v
import valibro as v
import valibro.unicode

schema := v.pipe(v.string(), v.bytes(4), v.code_points(1), v.graphemes(1))
assert v.is_valid(schema, '🙂')!
assert unicode.grapheme_count('e\u0301') == 1
assert unicode.grapheme_boundaries('ab') == [0, 1, 2]
```

## Normalize and case-map

`normalize()` defaults to NFC; pass `.nfd`, `.nfkc`, or `.nfkd` explicitly. Default Unicode upper/lower mapping includes expansions and contextual final sigma. It is not locale-specific casing.

```v
import valibro as v
import valibro.unicode

assert v.parse(v.pipe(v.string(), v.normalize()), 'e\u0301')! == 'é'
assert v.parse(v.pipe(v.string(), v.to_upper_case()), 'Straße')! == 'STRASSE'
assert unicode.to_lower('ΟΣ') == 'ος'
assert unicode.normalize('é', .nfd) == 'e\u0301'
```

## Words and emoji

Word segmentation follows default UAX #29 boundaries. A segment counts as a word when it contains a Unicode letter or number. Punctuation, whitespace, and emoji-only segments do not count. Boundaries are rune indexes, not byte offsets. There is no locale/dictionary tailoring for Thai, Chinese, Japanese, or other languages.

```v
import valibro as v
import valibro.unicode

assert unicode.word_count("don't stop!") == 2
assert unicode.word_count('🙂 👩🏽‍💻') == 0
assert v.is_valid(v.pipe(v.string(), v.words(2)), 'Hello world')!
assert v.is_valid(v.pipe(v.string(), v.emoji()), '🙂')!
```

Camel, Pascal, kebab, and snake transformations use case-style boundaries, not linguistic word segmentation. See [Unicode reference](/api/unicode/) for direct algorithms and [string actions](/guides/strings/) for pipeline checks.
