module schemas

import valibro.types
import encoding.utf8

// string accepts native, well-formed UTF-8 strings. Runtime unknown-value checks
// belong to adapters; malformed bytes fail before Unicode actions can run.
pub fn string(messages ...types.ErrorMessage) types.Schema[string, string] {
	assert messages.len <= 1, 'string accepts at most one custom message'
	text := if messages.len == 1 {
		messages[0]
	} else {
		types.ErrorMessage('Expected a valid UTF-8 string')
	}
	return types.Schema[string, string]{
		type_name: 'string'
		run:       fn [text] (input string, config types.Config) types.Dataset[string] {
			if !utf8.validate_str(input) {
				return types.Dataset[string]{
					typed:  false
					value:  input
					issues: [
						types.new_issue('string', text, 'UTF-8 string', 'invalid UTF-8'),
					]
				}
			}
			return types.Dataset[string]{
				value: input
			}
		}
	}
}
