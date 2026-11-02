module actions

import valibro.types
import valibro.utils

// max_length measures length; length uses UTF-16 code units.
pub fn max_length(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	assert requirement >= 0, 'max_length requires a non-negative count'
	text := custom_message(messages, 'Invalid length: expected <=${requirement}')
	return types.Action[string]{
		kind:      .validation
		type_name: 'max_length'
		run:       fn [requirement, text] (input string) types.Dataset[string] {
			count := utils.utf16_length(input)
			if count >= 0 && count <= requirement { return types.Dataset[string]{
					value: input
				} }
			return string_issue(input, 'max_length', text, '<=${requirement}', '${count}')
		}
	}
}
