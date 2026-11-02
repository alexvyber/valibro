module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const iso_time_regex = r'^(?:0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$'

pub fn iso_time(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('iso_time', iso_time_regex, messages)
}
