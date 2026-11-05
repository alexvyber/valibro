module main

import encoding.html
import math
import os
import strconv

// Check rendered text independently of token classification, allowing only the
// highlighting spans as markup. This also rejects accidental raw HTML injection.
fn highlighted_text(markup string) string {
	mut rest := markup
	mut text := ''
	for rest.contains('<') {
		text += rest.all_before('<')
		tag := rest.all_after('<').all_before('>')
		assert tag.starts_with('span class="hl-') || tag == '/span'
		rest = rest.all_after('>')
	}
	return html.unescape(text + rest, all: true)
}

fn test_highlight_token_categories_and_generic_calls() {
	source := "pub fn identity[T](value T) T {\n\t// Keep it\n\treturn value\n}\nmut count := 42\nvalid := true\nname := 'Alex'\nprintln(identity[string](name))\n"
	markup := highlight_v(source)
	for pair in [['keyword', 'pub'], ['keyword', 'return'], ['function', 'identity'],
		['function', 'println'], ['type', 'string'], ['comment', '// Keep it'],
		['number', '42'], ['boolean', 'true'], ['operator', ':='],
		['punctuation', '(']] {
		assert markup.contains('<span class="hl-${pair[0]}">${pair[1]}</span>')
	}
	assert highlighted_text(markup) == source
}

fn test_highlight_preserves_exact_source_and_escapes_html() {
	samples := ['', ' \t\r\n', "\tname := '世界'  \r\n\r\n", r"s := '${user.name}: <&>'",
		r"s := r'\d+<&>'", r's := "a quoted string"', 'c := `界`',
		'/* outer /* inner */ done */\nx := 0xff + 1.25e-3\n',
		"// <script>&amp;\ntext := '<img src=x>'\n", r"s := 'escaped \' quote and \\ slash'",
		'values := []string{}\nvalue := values[0]\n']
	for source in samples {
		markup := highlight_v(source)
		assert highlighted_text(markup) == source
		assert !markup.contains('<script>')
		assert !markup.contains('<img')
	}
}

fn test_highlight_lexer_errors_fall_back_without_exiting() {
	for source in ["name := 'unclosed", '/* unclosed', 'x := `'] {
		assert highlight_v(source) == escape(source)
	}
	assert highlight_v('assert true').contains('hl-keyword')
}

fn test_markdown_highlights_signatures_without_running_them() {
	signature := 'fn pipe[I, O](schema types.Schema[I, O]) types.Schema[I, O]'
	doc :=
		markdown('```v signature\n${signature}\n```\n\n```v\nassert true\n```\n\n```sh\nv run site\n```\n\n```text\nfn plain()\n```')!
	assert doc.examples == ['assert true\n']
	assert doc.html.contains('<span class="hl-function">pipe</span>')
	assert doc.html.contains('<code class="language-v">')
	assert doc.html.contains('<code class="language-sh">v run site\n</code>')
	assert doc.html.contains('<code class="language-text">fn plain()\n</code>')
}

fn test_all_documented_examples_and_signatures_preserve_text() {
	for page in load_pages(@VMODROOT)! {
		for example in page.document.examples {
			assert highlighted_text(highlight_v(example)) == example
		}
		if page.symbol != '' {
			assert page.document.html.contains('<span class="hl-function">${page.symbol}</span>')
			assert page.document.html.contains('<span class="hl-keyword">fn</span>')
		}
	}
}

// Read actual CSS palettes so changing a theme cannot silently make code tokens
// unreadable. Every token color should meet normal-text contrast on code blocks.
fn test_highlight_light_and_dark_color_contrast() {
	css := os.read_file(os.join_path(@VMODROOT, 'site/assets/site.css'))!
	palettes := [css.all_after(':root {').all_before('}'), css.all_after(":root[data-theme='dark'] {").all_before('}')]
	for palette in palettes {
		for background_key in ['--paper', '--panel'] {
			background := palette.all_after(background_key + ':').all_before(';').trim_space()
			for key in ['--blue', '--string', '--type', '--number', '--secondary', '--ink'] {
				foreground := palette.all_after(key + ':').all_before(';').trim_space()
				a := luminance(foreground)
				b := luminance(background)
				contrast := (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05)
				assert contrast >= 4.5, '${foreground} on ${background}: ${contrast}'
			}
		}
	}
}

fn luminance(hex string) f64 {
	assert hex.len == 7 && hex.starts_with('#')
	mut channels := []f64{}
	for start in [1, 3, 5] {
		value := f64(strconv.parse_int(hex[start..start + 2], 16, 32) or { panic(err) }) / 255.0
		channels << if value <= 0.04045 {
			value / 12.92
		} else {
			math.pow((value + 0.055) / 1.055, 2.4)
		}
	}
	return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722
}
