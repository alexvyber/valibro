module actions

import valibro.types

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn iso_date(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('iso_date', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn iso_date_time(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('iso_date_time', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn iso_date_time_second(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('iso_date_time_second', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn iso_time(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('iso_time', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn iso_time_second(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('iso_time_second', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn iso_timestamp(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('iso_timestamp', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn iso_week(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('iso_week', messages)
}
