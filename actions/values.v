module actions

import valibro.types

pub fn values(requirements []string, messages ...types.ErrorMessage) types.Action[string] {
	items := requirements.clone()
	return string_predicate('values', fn [items] (input string) bool {
		return input in items
	}, messages)
}
