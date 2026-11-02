module actions

import valibro.types
import valibro.utils

pub fn url(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('url', utils.valid_url, messages)
}
