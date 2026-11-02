module actions

import valibro.types
import valibro.utils
import math.big

pub fn to_bigint(messages ...types.ErrorMessage) types.Transformation[string, big.Integer] {
	text := custom_message(messages, 'Invalid bigint')
	return types.Transformation[string, big.Integer]{
		type_name: 'to_bigint'
		run:       fn [text] (input string) types.Dataset[big.Integer] {
			converted := utils.bigint_from_string(input) or {
				return types.Dataset[big.Integer]{
					typed:  false
					issues: [types.new_issue('to_bigint', text, '', input)]
				}
			}
			return types.Dataset[big.Integer]{
				value: converted
			}
		}
	}
}
