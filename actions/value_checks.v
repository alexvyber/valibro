module actions

import valibro.internal.comparison
import valibro.internal.diagnostics
import valibro.types

pub fn value[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	return value_predicate[T]('value', diagnostics.value_label[T](requirement), fn [requirement] [T](input T) bool {
		return comparison.value_equal(input, requirement)
	}, messages)
}

pub fn not_value[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	return value_predicate[T]('not_value', diagnostics.value_label[T](requirement), fn [requirement] [T](input T) bool {
		return !comparison.value_equal(input, requirement)
	}, messages)
}

pub fn values[T](requirements []T, messages ...types.ErrorMessage) types.Action[T] {
	items := requirements.clone()
	return value_predicate[T]('values', diagnostics.joined_values[T](items), fn [items] [T](input T) bool {
		for item in items {
			if comparison.value_equal(input, item) { return true }
		}
		return false
	}, messages)
}

pub fn not_values[T](requirements []T, messages ...types.ErrorMessage) types.Action[T] {
	items := requirements.clone()
	return value_predicate[T]('not_values', diagnostics.joined_values[T](items), fn [items] [T](input T) bool {
		for item in items {
			if comparison.value_equal(input, item) { return false }
		}
		return true
	}, messages)
}

pub fn min_value[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	return value_predicate[T]('min_value', diagnostics.value_label[T](requirement), fn [requirement] [T](input T) bool {
		return comparison.compare_value[T](input, requirement, 'min_value')
	}, messages)
}

pub fn max_value[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	return value_predicate[T]('max_value', diagnostics.value_label[T](requirement), fn [requirement] [T](input T) bool {
		return comparison.compare_value[T](input, requirement, 'max_value')
	}, messages)
}

pub fn gt_value[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	return value_predicate[T]('gt_value', diagnostics.value_label[T](requirement), fn [requirement] [T](input T) bool {
		return comparison.compare_value[T](input, requirement, 'gt_value')
	}, messages)
}

pub fn lt_value[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	return value_predicate[T]('lt_value', diagnostics.value_label[T](requirement), fn [requirement] [T](input T) bool {
		return comparison.compare_value[T](input, requirement, 'lt_value')
	}, messages)
}

fn value_predicate[T](code string, expected string, predicate fn (T) bool, messages []types.ErrorMessage) types.Action[T] {
	text := custom_message(messages, '')
	expects := match code {
		'min_value' { '>=' + expected }
		'max_value' { '<=' + expected }
		'gt_value' { '>' + expected }
		'lt_value' { '<' + expected }
		'not_value', 'not_values' { '!' + expected }
		'finite', 'integer', 'safe_integer' { '' }
		else { expected }
	}

	label := if code in ['min_value', 'max_value', 'gt_value', 'lt_value', 'value', 'not_value',
		'values', 'not_values'] {
		'value'
	} else {
		code.replace('_', ' ')
	}
	return types.Action[T]{
		kind:      .validation
		type_name: code
		run:       fn [code, expects, predicate, text, label] [T](input T) types.Dataset[T] {
			if predicate(input) { return types.Dataset[T]{
					value: input
				} }
			return validation_failure[T](input, code, label, expects,
				diagnostics.value_label[T](input), text)
		}
	}
}
