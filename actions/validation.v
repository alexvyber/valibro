module actions

import valibro.internal.text as textops
import valibro.types

fn custom_message(messages []types.ErrorMessage, fallback string) types.ErrorMessage {
	assert messages.len <= 1, 'Expected at most one custom message'
	return if messages.len == 1 { messages[0] } else { types.ErrorMessage(types.DefaultMessage{
			text: fallback
		}) }
}

fn string_issue(input string, code string, message types.ErrorMessage, expected string, received string) types.Dataset[string] {
	return types.Dataset[string]{
		value:  input
		issues: [types.new_issue(code, message, expected, received)]
	}
}

fn string_validation(code string, pattern string, messages []types.ErrorMessage) types.Action[string] {
	return string_validation_with_flags(code, pattern, '', messages)
}

fn format_failure(input string, code string, text types.ErrorMessage) types.Dataset[string] {
	received := '"' + input + '"'
	resolved_message := if text is types.DefaultMessage { types.ErrorMessage(types.DefaultMessage{
			text: 'Invalid ' + format_label(code) + ': Received ' + received
		}) } else { text }
	return types.Dataset[string]{
		value:  input
		issues: [
			types.new_issue(code, resolved_message, '', received, 'Invalid ' + format_label(code) +
				': Received ' + received),
		]
	}
}

fn string_validation_with_flags(code string, pattern string, flags string, messages []types.ErrorMessage) types.Action[string] {
	compiled := textops.compile_pattern_with_flags(pattern, flags) or {
		panic('Invalid ${code} pattern: ${err}')
	}
	text := custom_message(messages, '')
	return types.Action[string]{
		kind:      .validation
		type_name: code
		run:       fn [code, compiled, text] (input string) types.Dataset[string] {
			matched := compiled.find(input) != none
			if matched { return types.Dataset[string]{
					value: input
				} }
			return format_failure(input, code, text)
		}
	}
}

fn validation_failure[T](input T, code string, label string, expected string, received string, text types.ErrorMessage) types.Dataset[T] {
	return failure[T](input, code, label, expected, received, text, .validation)
}

fn failure[T](input T, code string, label string, expected string, received string, text types.ErrorMessage, kind types.IssueKind) types.Dataset[T] {
	prefix := 'Invalid ' + label + ': ' + if expected != '' { 'Expected ' + expected +
		' but received ' } else { 'Received ' }
	message := prefix + received
	resolved := if text is types.DefaultMessage { types.ErrorMessage(types.DefaultMessage{
			text: message
		}) } else { text }
	return types.Dataset[T]{
		value:  input
		issues: [types.issue_of_kind(code, resolved, expected, received, kind, message)]
	}
}

fn conversion_failure[O](code string, label string, expected string, received string, text types.ErrorMessage) types.Dataset[O] {
	mut result := types.Dataset[O]{}
	$if O is $sumtype {
		result = failure[O](O{}, code, label, expected, received, text, .transformation)
	} $else {
		result = failure[O](O{}, code, label, expected, received, text, .transformation)
	}
	issue := result.issues[0]
	return types.Dataset[O]{
		typed:  false
		issues: [types.Issue{ ...issue, kind: .transformation }]
	}
}

fn conversion_failure_input[I, O](input I, code string, label string, expected string, received string, text types.ErrorMessage) types.Dataset[O] {
	result := conversion_failure[O](code, label, expected, received, text)
	return types.Dataset[O]{
		...result
		raw_value: types.value_of[I](input)
	}
}
