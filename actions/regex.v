module actions

import regex.pcre
import alexvyber.js_runtime
import sync
import x.json2
import valibro.jsoncodec
import valibro.internal.text as textops
import valibro.types

// Fallible native compilation shared by the public facade and regex actions.
pub fn compile_regex(pattern string, flags string) !pcre.Regex {
	return textops.compile_pattern_with_flags(pattern, flags)
}

// ECMAScript RegExp validation preserves source, flags and stateful lastIndex semantics.
pub fn regex(pattern string, messages ...types.ErrorMessage) types.Action[string] {
	return regex_with_flags(pattern, '', ...messages)
}

pub fn regex_with_flags(pattern string, flags string, messages ...types.ErrorMessage) types.Action[string] {
	compiled := javascript_regex(pattern, flags, '', 0) or {
		panic('Invalid ECMAScript regular expression: ' + err.msg())
	}
	source := (compiled['source'] or { json2.Any('') }).str()
	canonical_flags := (compiled['flags'] or { json2.Any('') }).str()
	expected := '/' + source + '/' + canonical_flags
	text := custom_message(messages, '')
	state := &RegexState{}
	return types.Action[string]{
		kind:             .validation
		type_name:        'regex'
		requirement_text: jsoncodec.stringify(json2.Any({
			'pattern': json2.Any(source)
			'flags':   json2.Any(canonical_flags)
		})) or { panic(err) }
		run:              fn [pattern, canonical_flags, expected, text, state] (input string) types.Dataset[string] {
			state.guard.lock()
			defer { state.guard.unlock() }
			result := javascript_regex(pattern, canonical_flags, input, state.last_index) or {
				return types.Dataset[string]{
					value:     input
					exception: err
				}
			}
			mut position := unsafe { &RegexState(state) }
			position.last_index = (result['lastIndex'] or { json2.Any(0) }).int()
			if (result['matched'] or { json2.Any(false) }).bool() { return types.Dataset[string]{
					value: input
				} }
			received := jsoncodec.stringify(json2.Any(input)) or { panic(err) }
			resolved := if text is types.DefaultMessage { types.ErrorMessage(types.DefaultMessage{
					text: 'Invalid format: Expected ' + expected + ' but received ' + received
				}) } else { text }
			return types.Dataset[string]{
				value:  input
				issues: [
					types.new_issue('regex', resolved, expected, received,

						'Invalid format: Expected ' + expected + ' but received ' + received),
				]
			}
		}
	}
}

@[heap]
struct RegexState {
	guard &sync.Mutex = sync.new_mutex()
mut:
	last_index int
}

fn javascript_regex(pattern string, flags string, input string, last_index int) !map[string]json2.Any {
	program := 'const re = new RegExp(__input.pattern, __input.flags); re.lastIndex=__input.lastIndex; const matched=re.test(__input.value); globalThis.__result=JSON.stringify({matched,lastIndex:re.lastIndex,source:re.source,flags:re.flags});'
	encoded := jsoncodec.stringify(json2.Any({
		'pattern':   json2.Any(pattern)
		'flags':     json2.Any(flags)
		'value':     json2.Any(input)
		'lastIndex': json2.Any(last_index)
	}))!
	raw := js_runtime.evaluate(program, encoded,
		timeout_ms:   0
		memory_bytes: 0
		output_bytes: usize(pattern.len * 8 + 4096)
	)!
	decoded := jsoncodec.decode(raw)!
	return decoded.as_map()
}

// Each find allocates its own match state; schema copies are independent.
pub fn regex_object(regexp pcre.Regex, messages ...types.ErrorMessage) types.Action[string] {
	return regex_action(regexp, regexp.pattern, '', ...messages)
}

fn regex_action(regexp pcre.Regex, pattern string, flags string, messages ...types.ErrorMessage) types.Action[string] {
	text := custom_message(messages, '')
	source := regex_source(pattern)
	mut sorted_flags := flags.bytes()
	sorted_flags.sort()
	canonical_flags := sorted_flags.bytestr()
	expected := '/' + source + '/' + canonical_flags
	return types.Action[string]{
		kind:             .validation
		type_name:        'regex'
		requirement_text: jsoncodec.stringify(json2.Any({
			'pattern': json2.Any(source)
			'flags':   json2.Any(canonical_flags)
		})) or { panic(err) }
		run:              fn [regexp, text, expected] (input string) types.Dataset[string] {
			matched := regexp.find(input) != none
			if matched { return types.Dataset[string]{
					value: input
				} }
			received := '"' + input + '"'
			resolved_message := if text is types.DefaultMessage { types.ErrorMessage(types.DefaultMessage{
					text: 'Invalid format: Expected ' + expected + ' but received ' + received
				}) } else { text }
			return types.Dataset[string]{
				value:  input
				issues: [
					types.new_issue('regex', resolved_message, expected, received,

						'Invalid format: Expected ' + expected + ' but received ' + received),
				]
			}
		}
	}
}

// RegExp.source escapes delimiters and line terminators without changing matches.
fn regex_source(pattern string) string {
	if pattern == '' { return '(?:)' }
	mut output := ''
	mut backslashes := 0
	for character in pattern.runes() {
		if character == `/` && backslashes % 2 == 0 {
			output += '\\/'
		} else if character == `\n` {
			output += '\\n'
		} else if character == `\r` {
			output += '\\r'
		} else if character == rune(0x2028) {
			output += '\\u2028'
		} else if character == rune(0x2029) {
			output += '\\u2029'
		} else {
			output += character.str()
		}
		backslashes = if character == `\\` { backslashes + 1 } else { 0 }
	}
	return output
}
