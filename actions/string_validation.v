module actions

import valibro.types
import valibro.utils

fn custom_message(messages []types.ErrorMessage, fallback string) types.ErrorMessage {
	assert messages.len <= 1, 'Expected at most one custom message'
	return if messages.len == 1 { messages[0] } else { types.ErrorMessage(fallback) }
}

fn string_issue(input string, code string, message types.ErrorMessage, expected string, received string) types.Dataset[string] {
	return types.Dataset[string]{
		value:  input
		issues: [types.new_issue(code, message, expected, received)]
	}
}

fn string_validation(code string, pattern string, messages []types.ErrorMessage) types.Action[string] {
	compiled := utils.compile_pattern(pattern) or { panic('Invalid ${code} pattern: ${err}') }
	text := custom_message(messages, 'Invalid ${code}')
	return types.Action[string]{
		kind:      .validation
		type_name: code
		run:       fn [code, pattern, compiled, text] (input string) types.Dataset[string] {
			if _ := compiled.find(input) { return types.Dataset[string]{
					value: input
				} }
			return string_issue(input, code, text, pattern, input)
		}
	}
}
