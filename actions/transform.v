module actions

import valibro.types

pub fn transform[T](operation fn (T) T) types.Action[T] {
	return types.Action[T]{
		kind:      .transformation
		type_name: 'transform'
		run:       fn [operation] [T](input T) types.Dataset[T] {
			return types.Dataset[T]{
				value: operation(input)
			}
		}
	}
}

pub fn transform_to[I, O](operation fn (I) O) types.Transformation[I, O] {
	return types.Transformation[I, O]{
		type_name: 'transform'
		run:       fn [operation] [I, O](input I) types.Dataset[O] {
			return types.Dataset[O]{
				value: operation(input)
			}
		}
	}
}
