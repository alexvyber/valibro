module actions

import valibro.types

pub fn not_values(requirements []string, messages ...types.ErrorMessage) types.Action[string] {
	items := requirements.clone()
	return string_predicate('not_values', fn [items] (input string) bool {
		return input !in items
	}, messages)
}
