module actions

import valibro.types
import valibro.utils

pub fn domain(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('domain', utils.valid_domain, messages)
}
