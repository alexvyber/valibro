module actions

import valibro.types

pub fn starts_with(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	text := custom_message(messages, 'Invalid starts_with')
	return types.Action[string]{
		kind:      .validation
		type_name: 'starts_with'
		run:       fn [requirement, text] (input string) types.Dataset[string] {
			if input.starts_with(requirement) { return types.Dataset[string]{
					value: input
				} }
			return string_issue(input, 'starts_with', text, requirement, input)
		}
	}
}
