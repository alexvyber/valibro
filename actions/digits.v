module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const digits_regex = r'^[0-9]+$'

pub fn digits(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('digits', digits_regex, messages)
}
