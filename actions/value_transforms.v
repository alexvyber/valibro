module actions

import valibro.internal.comparison
import valibro.types

pub fn to_min_value[T](requirement T) types.Action[T] {
	return types.Action[T]{
		kind:      .transformation
		type_name: 'to_min_value'
		run:       fn [requirement] [T](input T) types.Dataset[T] {
			return types.Dataset[T]{
				value: if comparison.compare_value[T](input, requirement, 'lt_value') {
					requirement
				} else {
					input
				}
			}
		}
	}
}

pub fn to_max_value[T](requirement T) types.Action[T] {
	return types.Action[T]{
		kind:      .transformation
		type_name: 'to_max_value'
		run:       fn [requirement] [T](input T) types.Dataset[T] {
			return types.Dataset[T]{
				value: if comparison.compare_value[T](input, requirement, 'gt_value') {
					requirement
				} else {
					input
				}
			}
		}
	}
}
