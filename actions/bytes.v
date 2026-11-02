module actions

import valibro.types

// bytes measures bytes; length uses UTF-16 code units.
pub fn bytes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	assert requirement >= 0, 'bytes requires a non-negative count'
	text := custom_message(messages, 'Invalid bytes: expected ${requirement}')
	return types.Action[string]{
		kind:      .validation
		type_name: 'bytes'
		run:       fn [requirement, text] (input string) types.Dataset[string] {
			count := input.len
			if count >= 0 && count == requirement { return types.Dataset[string]{
					value: input
				} }
			return string_issue(input, 'bytes', text, '${requirement}', '${count}')
		}
	}
}
