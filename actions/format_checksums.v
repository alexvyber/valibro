module actions

import valibro.internal.formats
import valibro.internal.text as textops
import valibro.types

pub fn credit_card(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('credit_card', fn (input string) bool {
		return formats.valid_credit_card(input)
	}, messages)
}

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const imei_regex = r'^[0-9]{15}$|^[0-9]{2}-[0-9]{6}-[0-9]{6}-[0-9]$'

pub fn imei(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('imei', fn (input string) bool {
		return textops.matches(imei_regex, input) && formats.luhn(input)
	}, messages)
}

pub fn isbn(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('isbn', fn (input string) bool {
		return formats.valid_isbn(input)
	}, messages)
}
