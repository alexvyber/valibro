module actions

import valibro.internal.comparison
import valibro.internal.diagnostics
import valibro.types

pub fn includes_item[T](requirement T, messages ...types.ErrorMessage) types.Action[[]T] {
	text := custom_message(messages, '')
	content := diagnostics.issue_value[T](requirement)
	return types.Action[[]T]{
		kind:      .validation
		type_name: 'includes'
		run:       fn [requirement, text, content] [T](input []T) types.Dataset[[]T] {
			mut found := false
			for value in input {
				if comparison.value_equal(value, requirement) {
					found = true
					break
				}
			}
			if found { return types.Dataset[[]T]{
					value: input
				} }
			return validation_failure[[]T](input, 'includes', 'content', content, '!' + content,
				text)
		}
	}
}

pub fn excludes_item[T](requirement T, messages ...types.ErrorMessage) types.Action[[]T] {
	text := custom_message(messages, '')
	content := diagnostics.issue_value[T](requirement)
	return types.Action[[]T]{
		kind:      .validation
		type_name: 'excludes'
		run:       fn [requirement, text, content] [T](input []T) types.Dataset[[]T] {
			mut found := false
			for value in input {
				if comparison.value_equal(value, requirement) {
					found = true
					break
				}
			}
			if !found { return types.Dataset[[]T]{
					value: input
				} }
			return validation_failure[[]T](input, 'excludes', 'content', '!' + content, content,
				text)
		}
	}
}

pub fn every_item[T](predicate fn (T, int) bool, messages ...types.ErrorMessage) types.Action[[]T] {
	text := custom_message(messages, '')
	return types.Action[[]T]{
		kind:      .validation
		type_name: 'every_item'
		run:       fn [predicate, text] [T](input []T) types.Dataset[[]T] {
			mut valid := true
			for i, item in input {
				if !predicate(item, i) {
					valid = false
					break
				}
			}
			if valid { return types.Dataset[[]T]{
					value: input
				} }
			return validation_failure[[]T](input, 'every_item', 'item', '', 'Array', text)
		}
	}
}

pub fn some_item[T](predicate fn (T, int) bool, messages ...types.ErrorMessage) types.Action[[]T] {
	text := custom_message(messages, '')
	return types.Action[[]T]{
		kind:      .validation
		type_name: 'some_item'
		run:       fn [predicate, text] [T](input []T) types.Dataset[[]T] {
			mut valid := false
			for i, item in input {
				if predicate(item, i) {
					valid = true
					break
				}
			}
			if valid { return types.Dataset[[]T]{
					value: input
				} }
			return validation_failure[[]T](input, 'some_item', 'item', '', 'Array', text)
		}
	}
}

pub fn check_items[T](predicate fn (T, int) bool, messages ...types.ErrorMessage) types.Action[[]T] {
	text := custom_message(messages, '')
	return types.Action[[]T]{
		kind:      .validation
		type_name: 'check_items'
		run:       fn [predicate, text] [T](input []T) types.Dataset[[]T] {
			mut issues := []types.Issue{}
			for i, item in input {
				if !predicate(item, i) { issues << types.Issue{
						...validation_failure[T](item, 'check_items', 'item', '', diagnostics.issue_value[T](item), text).issues[0]
						path:       [types.PathSegment(i)]
						path_types: ['array']
					} }
			}
			return types.Dataset[[]T]{
				value:  input
				issues: issues
			}
		}
	}
}
