module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const iso_week_regex = r'^[0-9]{4}-W(?:0[1-9]|[1-4][0-9]|5[0-3])$'

pub fn iso_week(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('iso_week', iso_week_regex, messages)
}
