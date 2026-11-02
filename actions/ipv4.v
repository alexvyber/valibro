module actions

import valibro.types
import valibro.utils

pub fn ipv4(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('ipv4', utils.ipv4_regex, messages)
}
