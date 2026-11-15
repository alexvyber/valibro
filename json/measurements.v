module json

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
				if (minimum && input.len >= requirement) || (!minimum && input.len <= requirement) {
					return types.Dataset[json2.Any]{
						value: input
					}
				}
				kind := if minimum { 'min_length' } else { 'max_length' }
				prefix := if minimum { '>=' } else { '<=' }
				expected := prefix + requirement.str()
				received := input.len.str()
				return types.Dataset[json2.Any]{
					value:  input
					issues: [
						types.new_issue(kind, types.DefaultMessage{
							text: 'Invalid length: Expected ${expected} but received ${received}'
						}, expected, received),
					]
				}
			}
			return type_issue('array', input, 'array')
		}
	}
}
