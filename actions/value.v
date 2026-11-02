module actions

import valibro.types

pub fn value(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('value', fn [requirement] (input string) bool {
		return input == requirement
	}, messages)
}
