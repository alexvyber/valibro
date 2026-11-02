module actions

import valibro.types
import valibro.utils

pub fn to_number(messages ...types.ErrorMessage) types.Transformation[string, f64] {
	text := custom_message(messages, 'Invalid number')
	return types.Transformation[string, f64]{
		type_name: 'to_number'
		run:       fn [text] (input string) types.Dataset[f64] {
			converted := utils.number_from_string(input) or {
				return types.Dataset[f64]{
					typed:  false
					issues: [types.new_issue('to_number', text, '', input)]
				}
			}
			return types.Dataset[f64]{
				value: converted
			}
		}
	}
}
