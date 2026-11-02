module actions

import valibro.types

// guard is a fatal refinement: later actions cannot run after it fails.
pub fn guard[T](predicate fn (T) bool, messages ...types.ErrorMessage) types.Action[T] {
	text := custom_message(messages, 'Invalid input')
	return types.Action[T]{
		kind:      .transformation
		type_name: 'guard'
		run:       fn [predicate, text] [T](input T) types.Dataset[T] {
			if predicate(input) { return types.Dataset[T]{
					value: input
				} }
			return types.Dataset[T]{
				typed:  false
				value:  input
				issues: [types.new_issue('guard', text, '', '')]
			}
		}
	}
}
