module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const mac_regex = r'^(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$|^(?:[0-9a-fA-F]{2}-){5}[0-9a-fA-F]{2}$|^(?:[0-9a-fA-F]{4}\.){2}[0-9a-fA-F]{4}$|^(?:[0-9a-fA-F]{2}:){7}[0-9a-fA-F]{2}$|^(?:[0-9a-fA-F]{2}-){7}[0-9a-fA-F]{2}$|^(?:[0-9a-fA-F]{4}\.){3}[0-9a-fA-F]{4}$|^(?:[0-9a-fA-F]{4}:){3}[0-9a-fA-F]{4}$'

pub fn mac(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('mac', mac_regex, messages)
}
