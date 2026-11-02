module actions

import valibro.types
import valibro.utils

// not_length measures length; length uses UTF-16 code units.
pub fn not_length(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	assert requirement >= 0, 'not_length requires a non-negative count'
	text := custom_message(messages, 'Invalid length: expected !=${requirement}')
	return types.Action[string]{
		kind:      .validation
		type_name: 'not_length'
		run:       fn [requirement, text] (input string) types.Dataset[string] {
			count := utils.utf16_length(input)
			if count >= 0 && count != requirement { return types.Dataset[string]{
					value: input
				} }
			return string_issue(input, 'not_length', text, '!=${requirement}', '${count}')
		}
	}
}
