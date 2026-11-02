module actions

import valibro.types
import valibro.utils

pub fn credit_card(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('credit_card', fn (input string) bool {
		return utils.valid_credit_card(input)
	}, messages)
}
