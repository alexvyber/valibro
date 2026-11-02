module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const ksuid_regex = r'^[a-zA-Z0-9]{27}$'

pub fn ksuid(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('ksuid', ksuid_regex, messages)
}
