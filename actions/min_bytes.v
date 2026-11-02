module actions

import valibro.types

// min_bytes measures bytes; length uses UTF-16 code units.
pub fn min_bytes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	assert requirement >= 0, 'min_bytes requires a non-negative count'
	text := custom_message(messages, 'Invalid bytes: expected >=${requirement}')
	return types.Action[string]{
		kind:      .validation
		type_name: 'min_bytes'
		run:       fn [requirement, text] (input string) types.Dataset[string] {
			count := input.len
			if count >= 0 && count >= requirement { return types.Dataset[string]{
					value: input
				} }
			return string_issue(input, 'min_bytes', text, '>=${requirement}', '${count}')
		}
	}
}
