module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const octal_regex = r'^(?:0o)?[0-7]+$'

pub fn octal(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('octal', octal_regex, messages)
}
