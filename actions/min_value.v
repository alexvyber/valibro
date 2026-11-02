module actions

import valibro.types
import valibro.utils

pub fn min_value(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('min_value', fn [requirement] (input string) bool {
		return utils.compare_utf16(input, requirement) >= 0
	}, messages)
}
