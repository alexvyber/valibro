module actions

import valibro.types

pub fn excludes(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('excludes', fn [requirement] (input string) bool {
		return !input.contains(requirement)
	}, messages)
}
