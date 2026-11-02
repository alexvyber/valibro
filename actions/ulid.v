module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const ulid_regex = r'^[0-7][0-9a-hjkmnp-tv-zA-HJKMNP-TV-Z]{25}$'

pub fn ulid(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('ulid', ulid_regex, messages)
}
