module actions

import valibro.types
import x.json2

// On strings, JSON.stringify returns a quoted JSON string.
pub fn stringify_json() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'stringify_json'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: json2.encode(input)
			}
		}
	}
}

pub fn stringify_json_value[T]() types.Transformation[T, string] {
	return types.Transformation[T, string]{
		type_name: 'stringify_json'
		run:       fn [T](input T) types.Dataset[string] {
			return types.Dataset[string]{
				value: json2.encode(input)
			}
		}
	}
}
