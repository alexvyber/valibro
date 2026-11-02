module actions

import valibro.types

// regex searches for a match. Patterns use V's regex.pcre syntax and may contain inline flags.
pub fn regex(pattern string, messages ...types.ErrorMessage) types.Action[string] {
	return string_validation('regex', pattern, messages)
}
