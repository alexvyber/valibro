module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const hexadecimal_regex = r'^(?:0[hx])?[0-9a-fA-F]+$'

pub fn hexadecimal(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('hexadecimal', hexadecimal_regex, messages)
}
