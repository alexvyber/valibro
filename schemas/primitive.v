module schemas

import valibro.types

fn schema_message(messages []types.ErrorMessage, fallback string) types.ErrorMessage {
	assert messages.len <= 1, 'Schema accepts at most one custom message'
	return if messages.len == 1 { messages[0] } else { types.ErrorMessage(types.DefaultMessage{
			text: fallback
		}) }
}

fn native_schema[T](name string, messages []types.ErrorMessage) types.Schema[T, T] {
	// Type mismatches are compile-time errors, as with string().
	text := schema_message(messages, 'Expected ${name}')
	return types.Schema[T, T]{
		type_name: name
		expects:   match name {
			'function' { 'Function' }
			'blob' { 'Blob' }
			'file' { 'File' }
			'promise' { 'Promise' }
			else { name }
		}
		message:   text
		run:       fn [T](input T, config types.Config) types.Dataset[T] {
			return types.Dataset[T]{
				value: input
			}
		}
	}
}
