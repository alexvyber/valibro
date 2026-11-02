module actions

import valibro.types
import valibro.utils

pub fn isbn(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('isbn', fn (input string) bool {
		return utils.valid_isbn(input)
	}, messages)
}
