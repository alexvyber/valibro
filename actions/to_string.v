module actions

import valibro.types

pub fn to_string() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'to_string'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: input
			}
		}
	}
}
