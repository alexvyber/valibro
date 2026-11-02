module actions

import valibro.types

// check extends validation without modifying the pipeline executor.
pub fn check[T](predicate fn (T) bool, messages ...types.ErrorMessage) types.Action[T] {
	message := custom_message(messages, 'Invalid input')
	return types.Action[T]{
		kind:      .validation
		type_name: 'check'
		run:       fn [predicate, message] [T](input T) types.Dataset[T] {
			if predicate(input) {
				return types.Dataset[T]{
					value: input
				}
			}
			return types.Dataset[T]{
				value:  input
				issues: [types.new_issue('check', message, '', '')]
			}
		}
	}
}
