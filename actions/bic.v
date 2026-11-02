module actions

import valibro.types
import valibro.utils

pub fn bic(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('bic', utils.valid_bic, messages)
}
