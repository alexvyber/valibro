module actions

import valibro.types

// not_bytes measures bytes; length uses UTF-16 code units.
pub fn not_bytes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	assert requirement >= 0, 'not_bytes requires a non-negative count'
	text := custom_message(messages, 'Invalid bytes: expected !=${requirement}')
	return types.Action[string]{
		kind:      .validation
		type_name: 'not_bytes'
		run:       fn [requirement, text] (input string) types.Dataset[string] {
			count := input.len
			if count >= 0 && count != requirement { return types.Dataset[string]{
					value: input
				} }
			return string_issue(input, 'not_bytes', text, '!=${requirement}', '${count}')
		}
	}
}
