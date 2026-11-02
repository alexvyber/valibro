module actions

import valibro.types
import valibro.utils

pub fn to_max_value(requirement string) types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'to_max_value'
		run:       fn [requirement] (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: if utils.compare_utf16(input, requirement) > 0 { requirement } else { input }
			}
		}
	}
}
