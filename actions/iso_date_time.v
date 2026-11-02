module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const iso_date_time_regex = r'^[0-9]{4}-(?:0[1-9]|1[0-2])-(?:[12][0-9]|0[1-9]|3[01])[T ](?:0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$'

pub fn iso_date_time(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('iso_date_time', iso_date_time_regex, messages)
}
