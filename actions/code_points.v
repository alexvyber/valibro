module actions

import valibro.types

// code_points measures code points; length uses UTF-16 code units.
pub fn code_points(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	assert requirement >= 0, 'code_points requires a non-negative count'
	text := custom_message(messages, 'Invalid code_points: expected ${requirement}')
	return types.Action[string]{
		kind:      .validation
		type_name: 'code_points'
		run:       fn [requirement, text] (input string) types.Dataset[string] {
			count := input.runes().len
			if count >= 0 && count == requirement { return types.Dataset[string]{
					value: input
				} }
			return string_issue(input, 'code_points', text, '${requirement}', '${count}')
		}
	}
}
