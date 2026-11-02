module actions

import valibro.types
import valibro.utils

pub fn to_pascal_case() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'to_pascal_case'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: utils.format_case(input, '', true, true)
			}
		}
	}
}
