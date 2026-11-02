module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const mac64_regex = r'^(?:[0-9a-fA-F]{2}:){7}[0-9a-fA-F]{2}$|^(?:[0-9a-fA-F]{2}-){7}[0-9a-fA-F]{2}$|^(?:[0-9a-fA-F]{4}\.){3}[0-9a-fA-F]{4}$|^(?:[0-9a-fA-F]{4}:){3}[0-9a-fA-F]{4}$'

pub fn mac64(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('mac64', mac64_regex, messages)
}
