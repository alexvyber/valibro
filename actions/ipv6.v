module actions

import valibro.types
import valibro.utils

pub fn ipv6(messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('ipv6', utils.ipv6_regex, messages)
}
