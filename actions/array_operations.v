module actions

import valibro.internal.comparison
import valibro.internal.diagnostics
import valibro.types

pub fn map_items[I, O](operation fn (I, int) O) types.Transformation[[]I, []O] {
	return map_items_with_array[I, O](fn [operation] [I, O](item I, index int, array []I) O {
		return operation(item, index)
	})
}

pub fn map_items_with_array[I, O](operation fn (I, int, []I) O) types.Transformation[[]I, []O] {
	return types.Transformation[[]I, []O]{
		type_name: 'map_items'
		run:       fn [operation] [I, O](input []I) types.Dataset[[]O] {
			mut output := []O{cap: input.len}
			for i, item in input {
				output << operation(item, i, input)
			}
			return types.Dataset[[]O]{
				value: output
			}
		}
	}
}

pub fn filter_items[T](predicate fn (T, int) bool) types.Action[[]T] {
	return filter_items_with_array[T](fn [predicate] [T](item T, index int, array []T) bool {
		return predicate(item, index)
	})
}

pub fn filter_items_with_array[T](predicate fn (T, int, []T) bool) types.Action[[]T] {
	return types.Action[[]T]{
		kind:      .transformation
		type_name: 'filter_items'
		run:       fn [predicate] [T](input []T) types.Dataset[[]T] {
			mut output := []T{}
			for i, item in input {
				if predicate(item, i, input) { output << item }
			}
			return types.Dataset[[]T]{
				value: output
			}
		}
	}
}

pub fn find_item[T](predicate fn (T, int) bool) types.Transformation[[]T, types.Maybe[T]] {
	return find_item_with_array[T](fn [predicate] [T](item T, index int, array []T) bool {
		return predicate(item, index)
	})
}

pub fn find_item_with_array[T](predicate fn (T, int, []T) bool) types.Transformation[[]T, types.Maybe[T]] {
	return types.Transformation[[]T, types.Maybe[T]]{
		type_name: 'find_item'
		run:       fn [predicate] [T](input []T) types.Dataset[types.Maybe[T]] {
			for i, item in input {
				if predicate(item, i, input) { return types.Dataset[types.Maybe[T]]{
						value: types.some(item)
					} }
			}
			return types.Dataset[types.Maybe[T]]{
				value: types.undefined_value[T]()
			}
		}
	}
}

pub fn reduce_items[T, A](operation fn (A, T, int) A, initial A) types.Transformation[[]T, A] {
	return reduce_items_with_array[T, A](fn [operation] [T, A](acc A, item T, index int, array []T) A {
		return operation(acc, item, index)
	}, initial)
}

pub fn reduce_items_with_array[T, A](operation fn (A, T, int, []T) A, initial A) types.Transformation[[]T, A] {
	return types.Transformation[[]T, A]{
		type_name: 'reduce_items'
		run:       fn [operation, initial] [T, A](input []T) types.Dataset[A] {
			mut value := initial
			for i, item in input {
				value = operation(value, item, i, input)
			}
			return types.Dataset[A]{
				value: value
			}
		}
	}
}

pub fn every_item[T](predicate fn (T, int) bool, messages ...types.ErrorMessage) types.Action[[]T] {
	return every_item_with_array[T](fn [predicate] [T](item T, index int, array []T) bool {
		return predicate(item, index)
	}, ...messages)
}

pub fn every_item_with_array[T](predicate fn (T, int, []T) bool, messages ...types.ErrorMessage) types.Action[[]T] {
	text := custom_message(messages, '')
	return types.Action[[]T]{
		kind:      .validation
		type_name: 'every_item'
		run:       fn [predicate, text] [T](input []T) types.Dataset[[]T] {
			mut valid := true
			for i, item in input {
				if !predicate(item, i, input) {
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
	return some_item_with_array[T](fn [predicate] [T](item T, index int, array []T) bool {
		return predicate(item, index)
	}, ...messages)
}

pub fn some_item_with_array[T](predicate fn (T, int, []T) bool, messages ...types.ErrorMessage) types.Action[[]T] {
	text := custom_message(messages, '')
	return types.Action[[]T]{
		kind:      .validation
		type_name: 'some_item'
		run:       fn [predicate, text] [T](input []T) types.Dataset[[]T] {
			mut valid := false
			for i, item in input {
				if predicate(item, i, input) {
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
	return check_items_with_array[T](fn [predicate] [T](item T, index int, array []T) bool {
		return predicate(item, index)
	}, ...messages)
}

pub fn check_items_with_array[T](predicate fn (T, int, []T) bool, messages ...types.ErrorMessage) types.Action[[]T] {
	text := custom_message(messages, '')
	return types.Action[[]T]{
		kind:      .validation
		type_name: 'check_items'
		run:       fn [predicate, text] [T](input []T) types.Dataset[[]T] {
			mut issues := []types.Issue{}
			for i, item in input {
				if !predicate(item, i, input) { issues << types.Issue{
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

pub fn sort_items[T](compare fn (T, T) int) types.Action[[]T] {
	return types.Action[[]T]{
		kind:      .transformation
		type_name: 'sort_items'
		run:       fn [compare] [T](input []T) types.Dataset[[]T] {
			return types.Dataset[[]T]{
				value: merge_sort(input, compare)
			}
		}
	}
}

fn merge_sort[T](input []T, compare fn (T, T) int) []T {
	if input.len < 2 { return input.clone() }
	middle := input.len / 2
	left := merge_sort(input[..middle], compare)
	right := merge_sort(input[middle..], compare)
	mut result := []T{cap: input.len}
	mut i := 0
	mut j := 0
	for i < left.len && j < right.len {
		if compare(left[i], right[j]) <= 0 {
			result << left[i]
			i++
		} else {
			result << right[j]
			j++
		}
	}
	for value in left[i..] {
		result << value
	}
	for value in right[j..] {
		result << value
	}
	return result
}
