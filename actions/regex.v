module actions

import regex.pcre
import valibro.internal.text as textops
import valibro.types

// Fallible native compilation shared by the public facade and regex actions.
pub fn compile_regex(pattern string, flags string) !pcre.Regex {
	return textops.compile_pattern_with_flags(pattern, flags)
}

// Native V regex.pcre search; compiled programs do not retain match state.
pub fn regex(pattern string, messages ...types.ErrorMessage) types.Action[string] {
	return regex_with_flags(pattern, '', ...messages)
}

pub fn regex_with_flags(pattern string, flags string, messages ...types.ErrorMessage) types.Action[string] {
	regexp := compile_regex(pattern, flags) or {
		panic('Invalid native regular expression: ${err}')
	}
	return regex_object(regexp, ...messages)
}

// Each find allocates its own match state; schema copies are independent.
pub fn regex_object(regexp pcre.Regex, messages ...types.ErrorMessage) types.Action[string] {
	text := custom_message(messages, '')
	expected := '/' + regexp.pattern + '/'
	return types.Action[string]{
		kind:      .validation
		type_name: 'regex'
		run:       fn [regexp, text, expected] (input string) types.Dataset[string] {
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
