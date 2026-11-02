module actions

import valibro.types
import valibro.utils
import time

pub fn to_date(messages ...types.ErrorMessage) types.Transformation[string, time.Time] {
	text := custom_message(messages, 'Invalid date')
	return types.Transformation[string, time.Time]{
		type_name: 'to_date'
		run:       fn [text] (input string) types.Dataset[time.Time] {
			converted := utils.date_from_string(input) or {
				return types.Dataset[time.Time]{
					typed:  false
					issues: [types.new_issue('to_date', text, '', input)]
				}
			}
			return types.Dataset[time.Time]{
				value: converted
			}
		}
	}
}
