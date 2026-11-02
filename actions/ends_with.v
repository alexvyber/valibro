module actions

import valibro.types

pub fn ends_with(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	text := custom_message(messages, 'Invalid ends_with')
	return types.Action[string]{
		kind:      .validation
		type_name: 'ends_with'
		run:       fn [requirement, text] (input string) types.Dataset[string] {
			if input.ends_with(requirement) { return types.Dataset[string]{
					value: input
				} }
			return string_issue(input, 'ends_with', text, requirement, input)
		}
	}
}
