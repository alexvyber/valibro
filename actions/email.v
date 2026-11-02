module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const email_regex = r'^[a-zA-Z0-9_+-]+(?:\.[a-zA-Z0-9_+-]+)*@[0-9a-zA-Z]+(?:[.-][0-9a-zA-Z]+)*\.[a-zA-Z]{2,}$'

pub fn email(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('email', email_regex, messages)
}
