# Third-party notices

## Valibot

Patterns, format/checksum logic, case-boundary rules, and test inputs were adapted
from [Valibot](https://github.com/open-circle/valibot), revision
`d72f76fcf70ccfa0a5ca341b80da1d440ac60b11` (package version 1.5.0).
Generated fixture outputs were evaluated against that same revision.

MIT License

Copyright (c) Fabian Hiller

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Unicode data

Unicode 17.0.0 character, normalization, casing, emoji, grapheme, and word-break
data and conformance fixtures are distributed under the Unicode data/software
license reproduced in `unicode/LICENSE`. Source hashes and the pinned data URL
are recorded in `unicode/SOURCES.json`. Algorithms implement UAX #15 and UAX #29.

## emoji-regex-xs grammar

The emoji sequence grammar follows the `emoji-regex-xs` v1.0.0 grammar included
in the pinned Valibot source. Copyright (c) 2025 Steven Levithan, MIT license;
see `unicode/EMOJI_REGEX_LICENSE`. The runtime implementation is pure V and uses
Unicode property tables rather than JavaScript regular expressions.
