module actions

import valibro.types

pub fn message[T](action types.Action[T], text types.ErrorMessage) types.Action[T] {
	return types.Action[T]{
		annotations: action.annotations
		kind:        action.kind
		type_name:   action.type_name
		run:         fn [action, text] [T](input T) types.Dataset[T] {
			dataset := action.run(input)
			mut issues := []types.Issue{cap: dataset.issues.len}
			for issue in dataset.issues {
				issues << types.Issue{
					...issue
					message: types.resolve_message(text, issue)
				}
			}
			return types.Dataset[T]{
				typed:  dataset.typed
				value:  dataset.value
				issues: issues
			}
		}
	}
}
