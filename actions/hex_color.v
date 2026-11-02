module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const hex_color_regex = r'^#(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$'

pub fn hex_color(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('hex_color', hex_color_regex, messages)
}
