module actions

import valibro.types

pub fn includes(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('includes', fn [requirement] (input string) bool {
		return input.contains(requirement)
	}, messages)
}
