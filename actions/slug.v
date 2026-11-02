module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const slug_regex = r'^[0-9a-z]+(?:[-_][0-9a-z]+)*$'

pub fn slug(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('slug', slug_regex, messages)
}
