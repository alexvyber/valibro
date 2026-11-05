module actions

import valibro.internal.coercion as coerce
import valibro.internal.comparison
import valibro.internal.date as dates
import valibro.internal.diagnostics
import valibro.internal.number as numbers
import math
import math.big
import time
import valibro.types
import valibro.unicode
import x.json2

pub fn to_number(messages ...types.ErrorMessage) types.Transformation[string, f64] {
	text := custom_message(messages, '')
	return types.Transformation[string, f64]{
		type_name: 'to_number'
		run:       fn [text] (input string) types.Dataset[f64] {
			converted := numbers.number_from_string(input) or {
				return types.Dataset[f64]{
					...conversion_failure[f64]('to_number', 'number', '', 'NaN', text)
					value: math.nan()
				}
			}
			return types.Dataset[f64]{
				value: converted
			}
		}
	}
}

pub fn to_number_from[T](messages ...types.ErrorMessage) types.Transformation[T, f64] {
	text := custom_message(messages, '')
	return types.Transformation[T, f64]{
		type_name: 'to_number'
		run:       fn [text] [T](input T) types.Dataset[f64] {
			value := coerce.native_number[T](input) or {
				received := if err is types.TypeError {
					diagnostics.issue_value(input)
				} else {
					'NaN'
				}
				failed := conversion_failure[f64]('to_number', 'number', '', received, text)
				if err is types.TypeError { return types.Dataset[f64]{
						...failed
						raw_value: types.value_of[T](input)
					} }
				return types.Dataset[f64]{
					...failed
					value: math.nan()
				}
			}
			return types.Dataset[f64]{
				value: value
			}
		}
	}
}

pub fn to_bigint(messages ...types.ErrorMessage) types.Transformation[string, big.Integer] {
	text := custom_message(messages, '')
	return types.Transformation[string, big.Integer]{
		type_name: 'to_bigint'
		run:       fn [text] (input string) types.Dataset[big.Integer] {
			converted := numbers.bigint_from_string(input) or {
				return conversion_failure_input[string, big.Integer](input, 'to_bigint', 'bigint',
					'', diagnostics.issue_value(input), text)
			}
			return types.Dataset[big.Integer]{
				value: converted
			}
		}
	}
}

pub fn to_bigint_from[T](messages ...types.ErrorMessage) types.Transformation[T, big.Integer] {
	text := custom_message(messages, '')
	return types.Transformation[T, big.Integer]{
		type_name: 'to_bigint'
		run:       fn [text] [T](input T) types.Dataset[big.Integer] {
			value := coerce.native_bigint[T](input) or {
				return conversion_failure_input[T, big.Integer](input, 'to_bigint', 'bigint', '',
					diagnostics.issue_value(input), text)
			}
			return types.Dataset[big.Integer]{
				value: value
			}
		}
	}
}

// Uses the standard V string.bool conversion.
pub fn to_boolean() types.Transformation[string, bool] {
	return types.Transformation[string, bool]{
		type_name: 'to_boolean'
		run:       fn (input string) types.Dataset[bool] {
			return types.Dataset[bool]{
				value: input.bool()
			}
		}
	}
}

pub fn to_boolean_from[T](messages ...types.ErrorMessage) types.Transformation[T, bool] {
	text := custom_message(messages, '')
	return types.Transformation[T, bool]{
		type_name: 'to_boolean'
		run:       fn [text] [T](input T) types.Dataset[bool] {
			value := coerce.native_boolean[T](input) or {
				return conversion_failure_input[T, bool](input, 'to_boolean', 'boolean', '',
					diagnostics.issue_value(input), text)
			}
			return types.Dataset[bool]{
				value: value
			}
		}
	}
}

pub fn to_date(messages ...types.ErrorMessage) types.Transformation[string, time.Time] {
	text := custom_message(messages, '')
	return types.Transformation[string, time.Time]{
		type_name: 'to_date'
		run:       fn [text] (input string) types.Dataset[time.Time] {
			converted := dates.date_from_string(input) or {
				return conversion_failure_input[types.InvalidDate, time.Time](types.InvalidDate{},
					'to_date', 'date', '', '"Invalid Date"', text)
			}
			return types.Dataset[time.Time]{
				value: converted
			}
		}
	}
}

pub fn to_date_from[T](messages ...types.ErrorMessage) types.Transformation[T, time.Time] {
	text := custom_message(messages, '')
	return types.Transformation[T, time.Time]{
		type_name: 'to_date'
		run:       fn [text] [T](input T) types.Dataset[time.Time] {
			value := coerce.native_date[T](input) or {
				received := if err is types.TypeError {
					diagnostics.issue_value(input)
				} else {
					'"Invalid Date"'
				}
				if err is types.TypeError {
					return conversion_failure_input[T, time.Time](input, 'to_date', 'date', '',
						received, text)
				}
				return conversion_failure_input[types.InvalidDate, time.Time](types.InvalidDate{},
					'to_date', 'date', '', received, text)
			}
			return types.Dataset[time.Time]{
				value: value
			}
		}
	}
}

pub fn to_string_from[T](messages ...types.ErrorMessage) types.Transformation[T, string] {
	text := custom_message(messages, '')
	return types.Transformation[T, string]{
		type_name: 'to_string'
		run:       fn [text] [T](input T) types.Dataset[string] {
			output := coerce.native_string_checked[T](input) or {
				return conversion_failure_input[T, string](input, 'to_string', 'string', '',
					diagnostics.issue_value(input), text)
			}
			return types.Dataset[string]{
				value: output
			}
		}
	}
}

pub fn parse_boolean(messages ...types.ErrorMessage) types.Transformation[string, bool] {
	return parse_boolean_impl(types.ParseBooleanConfig{}, true, messages)
}

pub fn parse_boolean_with_config(config types.ParseBooleanConfig, messages ...types.ErrorMessage) types.Transformation[string, bool] {
	return parse_boolean_impl(config, false, messages)
}

fn parse_boolean_impl(config types.ParseBooleanConfig, defaults bool, messages []types.ErrorMessage) types.Transformation[string, bool] {
	truthy := config.truthy.map(unicode.to_lower(it))
	falsy := config.falsy.map(unicode.to_lower(it))
	mut expectations := []string{}
	if defaults { expectations << ['true', '1'] }
	for item in config.truthy {
		expectations << diagnostics.issue_value(item)
	}
	if defaults { expectations << ['false', '0'] }
	for item in config.falsy {
		expectations << diagnostics.issue_value(item)
	}
	expected := diagnostics.join_expects(expectations)
	text := custom_message(messages, '')
	return types.Transformation[string, bool]{
		type_name: 'parse_boolean'
		run:       fn [truthy, falsy, expected, text] (input string) types.Dataset[bool] {
			normalized := unicode.to_lower(input)
			if normalized in truthy { return types.Dataset[bool]{
					value: true
				} }
			if normalized in falsy { return types.Dataset[bool]{
					value: false
				} }
			return conversion_failure_input[string, bool](input, 'parse_boolean', 'boolean',
				expected, diagnostics.issue_value(input), text)
		}
	}
}

fn default_boolean[T](input T) ?bool {
	$if T is string {
		text := unicode.to_lower(input)
		if text in ['true', '1', 'yes', 'y', 'on', 'enabled'] { return true }
		if text in ['false', '0', 'no', 'n', 'off', 'disabled'] { return false }
	} $else $if T is bool {
		return input
	} $else $if T is json2.Any {
		if types.is_json_number(input) { return default_boolean[f64](input.f64()) }
		match input {
			string { return default_boolean[string](input) }
			bool { return input }
			int { return default_boolean[int](input) }
			i64 { return default_boolean[i64](input) }
			u64 { return default_boolean[u64](input) }
			f64 { return default_boolean[f64](input) }
			f32 { return default_boolean[f32](input) }
			else {}
		}
	} $else $if T is i8 || T is i16 || T is int || T is i32 || T is i64 || T is u8 || T is u16
		|| T is u32 || T is u64 || T is isize || T is usize || T is f32 || T is f64 {
		if input == 0 { return false }
		if input == 1 { return true }
	}
	return none
}

pub fn parse_boolean_from[T](messages ...types.ErrorMessage) types.Transformation[T, bool] {
	text := custom_message(messages, '')
	expected := '(true | 1 | "true" | "1" | "yes" | "y" | "on" | "enabled" | false | 0 | "false" | "0" | "no" | "n" | "off" | "disabled")'
	return types.Transformation[T, bool]{
		type_name: 'parse_boolean'
		run:       fn [text, expected] [T](input T) types.Dataset[bool] {
			if output := default_boolean[T](input) { return types.Dataset[bool]{
					value: output
				} }
			return conversion_failure_input[T, bool](input, 'parse_boolean', 'boolean', expected,
				diagnostics.issue_value[T](input), text)
		}
	}
}

fn normalize_boolean_value[T](input T) T {
	$if T is string {
		return unicode.to_lower(input)
	} $else $if T is json2.Any {
		if input is string { return json2.Any(unicode.to_lower(input)) }
		return input
	} $else {
		return input
	}
}

pub fn parse_boolean_with_values[T](truthy []T, falsy []T, messages ...types.ErrorMessage) types.Transformation[T, bool] {
	mut requirements := truthy.clone()
	for value in falsy {
		requirements << value
	}
	expected := diagnostics.joined_values[T](requirements)
	positives := truthy.map(normalize_boolean_value[T](it))
	negatives := falsy.map(normalize_boolean_value[T](it))
	text := custom_message(messages, '')
	return types.Transformation[T, bool]{
		type_name: 'parse_boolean'
		run:       fn [positives, negatives, expected, text] [T](input T) types.Dataset[bool] {
			normalized := normalize_boolean_value[T](input)
			for value in positives {
				if comparison.value_equal[T](normalized, value) { return types.Dataset[bool]{
						value: true
					} }
			}
			for value in negatives {
				if comparison.value_equal[T](normalized, value) { return types.Dataset[bool]{
						value: false
					} }
			}
			return conversion_failure_input[T, bool](input, 'parse_boolean', 'boolean', expected,
				diagnostics.issue_value[T](input), text)
		}
	}
}
