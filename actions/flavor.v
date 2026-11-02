module actions

import valibro.types

pub fn flavor[B]() types.Transformation[string, types.Flavored[string, B]] {
	return types.Transformation[string, types.Flavored[string, B]]{
		type_name: 'flavor'
		run:       fn [B](input string) types.Dataset[types.Flavored[string, B]] {
			return types.Dataset[types.Flavored[string, B]]{
				value: types.Flavored[string, B]{
					value: input
				}
			}
		}
	}
}
