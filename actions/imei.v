module actions

import valibro.types
import valibro.utils

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const imei_regex = r'^[0-9]{15}$|^[0-9]{2}-[0-9]{6}-[0-9]{6}-[0-9]$'

pub fn imei(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('imei', fn (input string) bool {
		return utils.matches(imei_regex, input) && utils.luhn(input)
	}, messages)
}
