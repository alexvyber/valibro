module actions

import valibro.types

fn string_predicate(code string, predicate fn (string) bool, messages []types.ErrorMessage) types.Action[string] {
	text := custom_message(messages, 'Invalid ${code}')
	return types.Action[string]{
		kind:      .validation
		type_name: code
		run:       fn [code, predicate, text] (input string) types.Dataset[string] {
			if predicate(input) { return types.Dataset[string]{
					value: input
				} }
			return string_issue(input, code, text, code, input)
		}
	}
}
