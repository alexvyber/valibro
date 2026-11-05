module schemas

import valibro.types

pub fn boolean(messages ...types.ErrorMessage) types.Schema[bool, bool] {
	return native_schema[bool]('boolean', messages)
}
