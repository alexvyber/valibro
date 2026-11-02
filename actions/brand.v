module actions

import valibro.types

pub fn brand[B]() types.Transformation[string, types.Branded[string, B]] {
	return types.Transformation[string, types.Branded[string, B]]{
		type_name: 'brand'
		run:       fn [B](input string) types.Dataset[types.Branded[string, B]] {
			return types.Dataset[types.Branded[string, B]]{
				value: types.Branded[string, B]{
					value: input
				}
			}
		}
	}
}
