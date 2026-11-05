module schemas

import math.big
import valibro.types

pub fn bigint(messages ...types.ErrorMessage) types.Schema[big.Integer, big.Integer] {
	return native_schema[big.Integer]('bigint', messages)
}
