module schemas

import valibro.internal.date as dates
import time
import valibro.types

// date validates calendar fields and rebuilds V's cached Unix timestamp.
pub fn date(messages ...types.ErrorMessage) types.Schema[time.Time, time.Time] {
	text := schema_message(messages, 'Expected a valid date')
	return types.Schema[time.Time, time.Time]{
		type_name: 'date'
		expects:   'Date'
		message:   text
		run:       fn [text] (input time.Time, config types.Config) types.Dataset[time.Time] {
			rebuilt := dates.validated_native_date(input) or {
				return types.Dataset[time.Time]{
					typed:  false
					value:  input
					issues: [
						types.schema_type_issue('date', text, 'Date', '"Invalid Date"', 'type'),
					]
				}
			}
			return types.Dataset[time.Time]{
				value: rebuilt
			}
		}
	}
}
