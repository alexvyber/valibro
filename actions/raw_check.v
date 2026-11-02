module actions

import valibro.types

pub fn raw_check[T](operation fn (T) []types.Issue) types.Action[T] {
	return types.Action[T]{
		kind:      .validation
		type_name: 'raw_check'
		run:       fn [operation] [T](input T) types.Dataset[T] {
			return types.Dataset[T]{
				value:  input
				issues: operation(input)
			}
		}
	}
}
