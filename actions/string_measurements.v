module actions

import valibro.types

pub fn bytes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('bytes', requirement, '=', fn (input string) int {
		return input.len
	}, messages)
}

pub fn min_bytes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('min_bytes', requirement, '>=', fn (input string) int {
		return input.len
	}, messages)
}

pub fn max_bytes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('max_bytes', requirement, '<=', fn (input string) int {
		return input.len
	}, messages)
}

pub fn not_bytes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('not_bytes', requirement, '!=', fn (input string) int {
		return input.len
	}, messages)
}

pub fn length(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('length', requirement, '=', fn (input string) int {
		return input.runes().len
	}, messages)
}

pub fn min_length(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('min_length', requirement, '>=', fn (input string) int {
		return input.runes().len
	}, messages)
}

pub fn max_length(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('max_length', requirement, '<=', fn (input string) int {
		return input.runes().len
	}, messages)
}

pub fn not_length(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('not_length', requirement, '!=', fn (input string) int {
		return input.runes().len
	}, messages)
}

pub fn code_points(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('code_points', requirement, '=', fn (input string) int {
		return input.runes().len
	}, messages)
}

pub fn min_code_points(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('min_code_points', requirement, '>=', fn (input string) int {
		return input.runes().len
	}, messages)
}

pub fn max_code_points(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('max_code_points', requirement, '<=', fn (input string) int {
		return input.runes().len
	}, messages)
}

pub fn not_code_points(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('not_code_points', requirement, '!=', fn (input string) int {
		return input.runes().len
	}, messages)
}

fn count_check[T](code string, requirement int, relation string, counter fn (T) int, messages []types.ErrorMessage) types.Action[T] {
	text := custom_message(messages, '')
	prefix := match relation {
		'=' { '' }
		'!=' { '!' }
		else { relation }
	}

	expected := prefix + requirement.str()
	base := code.replace('min_', '').replace('max_', '').replace('not_', '')
	label := if code in ['empty', 'non_empty'] {
		'length'
	} else if base == 'code_points' {
		'code points'
	} else {
		base
	}
	return types.Action[T]{
		kind:      .validation
		type_name: code
		run:       fn [code, requirement, relation, counter, text, expected, label] [T](input T) types.Dataset[T] {
			count := counter(input)
			valid := match relation {
				'=' { count == requirement }
				'!=' { count != requirement }
				'>=' { count >= requirement }
				else { count <= requirement }
			}

			if valid { return types.Dataset[T]{
					value: input
				} }
			return validation_failure[T](input, code, label, expected, count.str(), text)
		}
	}
}
