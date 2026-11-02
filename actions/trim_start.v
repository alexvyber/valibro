module actions

import valibro.types
import valibro.utils

pub fn trim_start() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'trim_start'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: utils.trim(input, true, false)
			}
		}
	}
}
