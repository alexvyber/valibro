module actions

import valibro.types

// JavaScript Boolean(string): every nonempty string, including "false", is true.
pub fn to_boolean() types.Transformation[string, bool] {
	return types.Transformation[string, bool]{
		type_name: 'to_boolean'
		run:       fn (input string) types.Dataset[bool] {
			return types.Dataset[bool]{
				value: input != ''
			}
		}
	}
}
