module actions

import valibro.types

pub fn raw_transform[T](operation fn (T) types.Dataset[T]) types.Action[T] {
	return types.Action[T]{
		kind:      .transformation
		type_name: 'raw_transform'
		run:       operation
	}
}

pub fn raw_transform_to[I, O](operation fn (I) types.Dataset[O]) types.Transformation[I, O] {
	return types.Transformation[I, O]{
		type_name: 'raw_transform'
		run:       operation
	}
}
