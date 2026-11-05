module schemas

import valibro.internal.diagnostics
import math
import valibro.types

pub fn nan(messages ...types.ErrorMessage) types.Schema[f64, f64] {
	text := schema_message(messages, 'Expected NaN')
	return types.Schema[f64, f64]{
		type_name: 'nan'
		expects:   'NaN'
		message:   text
		run:       fn [text] (input f64, config types.Config) types.Dataset[f64] {
			if math.is_nan(input) { return types.Dataset[f64]{
					value: input
				} }
			return types.Dataset[f64]{
				typed:  false
				value:  input
				issues: [
					types.schema_type_issue('nan', text, 'NaN', diagnostics.issue_value(input),
						'type'),
				]
			}
		}
	}
}
