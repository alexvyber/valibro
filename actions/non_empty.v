module actions

import valibro.types

pub fn non_empty(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('non_empty', fn (input string) bool {
		return input != ''
	}, messages)
}
