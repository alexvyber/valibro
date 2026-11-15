module json

import valibro.actions
import valibro.types
import x.json2

// JSON collection measurements retain executable rules and wire metadata.
pub fn min_length(requirement int) types.Action[json2.Any] {
	return collection_measurement(requirement, true)
}

pub fn max_length(requirement int) types.Action[json2.Any] {
	return collection_measurement(requirement, false)
}

fn collection_measurement(requirement int, minimum bool) types.Action[json2.Any] {
	return types.Action[json2.Any]{
		kind:             .validation
		type_name:        if minimum { 'min_length' } else { 'max_length' }
		requirement_text: requirement.str()
		run:              fn [requirement, minimum] (input json2.Any) types.Dataset[json2.Any] {
			if input is []json2.Any {
				action := if minimum {
					actions.min_length_of[[]json2.Any](requirement)
				} else {
					actions.max_length_of[[]json2.Any](requirement)
				}
				result := action.run(input)
				return types.Dataset[json2.Any]{
					value:  input
					typed:  result.typed
					issues: result.issues
				}
			}
			return type_issue('array', input, 'array')
		}
	}
}
