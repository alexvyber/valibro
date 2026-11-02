module actions

import valibro.types

// Pattern adapted from Valibot (MIT); see THIRD_PARTY_NOTICES.md.
const base64_regex = r'(?i)^(?:[0-9a-z+/]{4})*(?:[0-9a-z+/]{2}==|[0-9a-z+/]{3}=)?$'

pub fn base64(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('base64', base64_regex, messages)
}
