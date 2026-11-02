module actions

import valibro.types

// Native V strings already have immutable contents.
pub fn readonly() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'readonly'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: input
			}
		}
	}
}
