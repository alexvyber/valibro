module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const isrc_regex = r'^(?:[A-Z]{2}[A-Z0-9]{3}[0-9]{7}|[A-Z]{2}-[A-Z0-9]{3}-[0-9]{2}-[0-9]{5})$'

pub fn isrc(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('isrc', isrc_regex, messages)
}
