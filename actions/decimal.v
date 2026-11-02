module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const decimal_regex = r'^[+-]?(?:[0-9]*\.)?[0-9]+$'

pub fn decimal(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('decimal', decimal_regex, messages)
}
