module actions

import valibro.types

pub fn empty(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('empty', fn (input string) bool {
		return input == ''
	}, messages)
}
