module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const mac48_regex = r'^(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$|^(?:[0-9a-fA-F]{2}-){5}[0-9a-fA-F]{2}$|^(?:[0-9a-fA-F]{4}\.){2}[0-9a-fA-F]{4}$'

pub fn mac48(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('mac48', mac48_regex, messages)
}
