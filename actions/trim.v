module actions

import valibro.types
import valibro.utils

pub fn trim() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'trim'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: utils.trim(input, true, true)
			}
		}
	}
}
