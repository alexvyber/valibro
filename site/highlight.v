module main

import strings
import v.pref
import v.scanner
import v.token

const v_builtin_types = ['bool', 'string', 'rune', 'char', 'byte', 'u8', 'u16', 'u32', 'u64', 'u128',
	'usize', 'i8', 'i16', 'int', 'i64', 'i128', 'isize', 'f32', 'f64', 'voidptr', 'byteptr',
	'charptr', 'any']

// Token positions select original source bytes: never reconstruct literals from
// Token.lit, which omits quotes and changes comments/interpolated strings.
fn highlight_v(source string) string {
	mut lexer := scanner.new_scanner(source, .parse_comments, &pref.Preferences{
		output_mode:  .silent
		fatal_errors: false
	})
	if lexer.errors.len > 0 { return escape(source) }
	mut tokens := []token.Token{}
	for {
		tok := lexer.scan()
		if tok.kind == .eof { break
		 }
		tokens << tok
	}
	mut out := strings.new_builder(source.len * 2)
	mut cursor := 0
	for index, tok in tokens {
		if tok.kind == .eof { break
		 }
		if tok.pos < cursor || tok.pos >= source.len || tok.len <= 0 { continue
		 }
		end := if tok.len > source.len - tok.pos { source.len } else { tok.pos + tok.len }
		out.write_string(escape(source[cursor..tok.pos]))
		text := escape(source[tok.pos..end])
		class := highlight_class(tokens, index)
		if class == '' {
			out.write_string(text)
		} else {
			out.write_string('<span class="hl-${class}">${text}</span>')
		}
		cursor = end
	}
	out.write_string(escape(source[cursor..]))
	return out.str()
}

fn highlight_class(tokens []token.Token, index int) string {
	tok := tokens[index]
	match tok.kind {
		.comment {
			return 'comment'
		}
		.string, .chartoken {
			return 'string'
		}
		.str_dollar {
			return 'operator'
		}
		.number {
			return 'number'
		}
		.key_true, .key_false {
			return 'boolean'
		}
		.name {
			if index > 0 && tokens[index - 1].kind == .key_fn { return 'function' }
			if index + 1 < tokens.len && tokens[index + 1].kind == .lpar { return 'function' }
			if generic_call(tokens, index) { return 'function' }
			if tok.lit in v_builtin_types { return 'type' }
			if tok.lit.len > 0 && tok.lit[0].is_capital() { return 'type' }
		}
		.lpar, .rpar, .lcbr, .rcbr, .lsbr, .rsbr, .comma, .dot, .colon, .semicolon, .ellipsis,
		.dotdot {
			return 'punctuation'
		}
		else {
			if tok.is_key() { return 'keyword' }
			if tok.kind.is_assign() || tok.is_unary() || tok.kind.is_relational()
				|| tok.kind.is_infix() || tok.kind.is_postfix() {
				return 'operator'
			}
		}
	}

	return ''
}

fn generic_call(tokens []token.Token, index int) bool {
	if index + 1 >= tokens.len || tokens[index + 1].kind != .lsbr { return false }
	mut depth := 0
	for i := index + 1; i < tokens.len; i++ {
		if tokens[i].kind == .lsbr { depth++ }
		if tokens[i].kind == .rsbr {
			depth--
			if depth == 0 { return i + 1 < tokens.len && tokens[i + 1].kind == .lpar }
		}
	}
	return false
}
