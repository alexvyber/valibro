module actions

import valibro.types

pub fn to_upper_case() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'to_upper_case'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: input.to_upper()
			}
		}
	}
}
