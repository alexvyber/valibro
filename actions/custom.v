module actions

import valibro.internal.diagnostics
import valibro.types

// check extends validation without modifying the pipeline executor.
pub fn check[T](predicate fn (T) bool, messages ...types.ErrorMessage) types.Action[T] {
	message := custom_message(messages, '')
	return types.Action[T]{
		kind:      .validation
		type_name: 'check'
		run:       fn [predicate, message] [T](input T) types.Dataset[T] {
			if predicate(input) {
				return types.Dataset[T]{
					value: input
				}
			}
			return validation_failure[T](input, 'check', 'input', '',
				diagnostics.issue_value[T](input), message)
		}
	}
}

pub fn transform[T](operation fn (T) T) types.Action[T] {
	return types.Action[T]{
		kind:      .transformation
		type_name: 'transform'
		run:       fn [operation] [T](input T) types.Dataset[T] {
			return types.Dataset[T]{
				value: operation(input)
			}
		}
	}
}

pub fn transform_to[I, O](operation fn (I) O) types.Transformation[I, O] {
	return types.Transformation[I, O]{
		type_name: 'transform'
		run:       fn [operation] [I, O](input I) types.Dataset[O] {
			return types.Dataset[O]{
				value: operation(input)
			}
		}
	}
}

pub fn raw_check[T](operation fn (T) []types.Issue) types.Action[T] {
	return types.contextual_action[T]('raw_check', .validation, fn [operation] [T](dataset types.Dataset[T], config types.Config) types.Dataset[T] {
		mut issues := dataset.issues.clone()
		for issue in operation(dataset.value) {
			issues << types.Issue{
				...issue
				custom_message: issue.message != '' || issue.custom_message
			}
		}
		return types.Dataset[T]{
			...dataset
			issues: issues
		}
	})
}

// The context adapter can observe untyped datasets and parse-specific settings.
pub fn raw_check_with_context[T](operation fn (types.Dataset[T], types.Config) types.Dataset[T]) types.Action[T] {
	return types.contextual_action[T]('raw_check', .validation, operation)
}

pub fn raw_transform[T](operation fn (T) types.Dataset[T]) types.Action[T] {
	return raw_transform_with_context[T](fn [operation] [T](dataset types.Dataset[T], config types.Config) types.Dataset[T] {
		return operation(dataset.value)
	})
}

pub fn raw_transform_to[I, O](operation fn (I) types.Dataset[O]) types.Transformation[I, O] {
	return raw_transform_to_with_context[I, O](fn [operation] [I, O](dataset types.Dataset[I], config types.Config) types.Dataset[O] {
		return operation(dataset.value)
	})
}

pub fn raw_transform_with_context[T](operation fn (types.Dataset[T], types.Config) types.Dataset[T]) types.Action[T] {
	return types.contextual_action[T]('raw_transform', .transformation, fn [operation] [T](dataset types.Dataset[T], config types.Config) types.Dataset[T] {
		result := operation(dataset, config)
		if result.issues.len > 0 { return types.Dataset[T]{
				...result
				typed: false
				value: dataset.value
			} }
		return result
	})
}

pub fn raw_transform_to_with_context[I, O](operation fn (types.Dataset[I], types.Config) types.Dataset[O]) types.Transformation[I, O] {
	return types.contextual_transformation[I, O]('raw_transform', fn [operation] [I, O](dataset types.Dataset[I], config types.Config) types.Dataset[O] {
		result := operation(dataset, config)
		if result.issues.len > 0 {
			mut value := result.value
			$if I is O {
				$if O is $array {
					value = dataset.value.clone()
				} $else {
					value = dataset.value
				}
			}
			return types.Dataset[O]{
				...result
				raw_value: dataset.raw_value or { types.value_of[I](dataset.value) }
				value:     value
				typed:     false
			}
		}
		return result
	})
}

// guard is a fatal refinement: later actions cannot run after it fails.
pub fn guard[T](predicate fn (T) bool, messages ...types.ErrorMessage) types.Action[T] {
	text := custom_message(messages, '')
	return types.Action[T]{
		kind:      .transformation
		type_name: 'guard'
		run:       fn [predicate, text] [T](input T) types.Dataset[T] {
			if predicate(input) { return types.Dataset[T]{
					value: input
				} }
			failed := failure[T](input, 'guard', 'input', '', diagnostics.issue_value[T](input),
				text, .transformation)
			return types.Dataset[T]{
				...failed
				typed: false
			}
		}
	}
}
