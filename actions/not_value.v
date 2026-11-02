module actions

import valibro.types

pub fn not_value(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('not_value', fn [requirement] (input string) bool {
		return input != requirement
	}, messages)
}
