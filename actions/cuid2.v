module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const cuid2_regex = r'^[a-z][0-9a-z]*$'

pub fn cuid2(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('cuid2', cuid2_regex, messages)
}
