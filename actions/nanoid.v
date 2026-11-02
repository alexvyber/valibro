module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const nano_id_regex = r'^[a-zA-Z0-9_-]+$'

pub fn nanoid(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('nanoid', nano_id_regex, messages)
}
