module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const jws_compact_regex = r'^(?:[a-zA-Z0-9_-]{2,3}|(?:[a-zA-Z0-9_-]{4})+(?:[a-zA-Z0-9_-]{2,3})?)\.(?:[a-zA-Z0-9_-]{2,3}|(?:[a-zA-Z0-9_-]{4})+(?:[a-zA-Z0-9_-]{2,3})?)?\.(?:[a-zA-Z0-9_-]{2,3}|(?:[a-zA-Z0-9_-]{4})+(?:[a-zA-Z0-9_-]{2,3})?)?$'

pub fn jws_compact(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('jws_compact', jws_compact_regex, messages)
}
