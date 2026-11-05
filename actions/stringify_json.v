module actions

import valibro.internal.diagnostics
import valibro.internal.date as dates
import valibro.jsoncodec
import valibro.types
import math.big
import time
import x.json2

// Serialize a native V value; unsupported values return a validation issue.
pub fn stringify_json_value[T](config jsoncodec.StringifyConfig) types.Transformation[T, string] {
	return types.Transformation[T, string]{
		type_name: 'stringify_json'
		run:       fn [config] [T](input T) types.Dataset[string] {
			value := native_json_value(input) or {
				return conversion_failure_input[T, string](input, 'stringify_json', 'JSON', '',
					err.msg(), types.DefaultMessage{})
			}
			output := jsoncodec.stringify(value, config) or {
				return conversion_failure_input[T, string](input, 'stringify_json', 'JSON', '',
					err.msg(), types.DefaultMessage{})
			}
			return types.Dataset[string]{
				value: output
			}
		}
	}
}

fn native_json_value[T](input T) !json2.Any {
	$if T is $option {
		return native_json_optional_value(input)
	} $else $if T is $pointer {
		if input == unsafe { nil } { return json2.Null{} }
		return native_json_value(*input)
	} $else $if T is json2.Any {
		return input
	} $else $if T is time.Time {
		valid := dates.validated_native_date(input)!
		return json2.Any(diagnostics.value_label(valid))
	} $else $if T is types.InvalidDate {
		return json2.Null{}
	} $else $if T is big.Integer {
		return error('Convert big.Integer explicitly to a JSON string or number')
	} $else $if T is string || T is bool || T is f64 || T is f32 || T is int || T is i64 || T is u64
		|| T is i8 || T is i16 || T is i32 || T is u8 || T is u16 || T is u32 {
		return json2.Any(input)
	} $else $if T is isize {
		return json2.Any(i64(input))
	} $else $if T is usize {
		return json2.Any(u64(input))
	} $else $if T is $function {
		return error('Functions cannot be encoded as JSON')
	} $else $if T is $array || T is $array_fixed {
		mut output := []json2.Any{}
		for item in input {
			output << native_json_value(item)!
		}
		return json2.Any(output)
	} $else $if T is $map {
		mut output := map[string]json2.Any{}
		for key, item in input {
			output[key.str()] = native_json_value(item)!
		}
		return json2.Any(output)
	} $else $if T is json2.JsonEncoder || T is json2.Encodable {
		return jsoncodec.decode(json2.encode(input))
	} $else $if T is $struct {
		return native_json_struct(input, []string{}, '')
	} $else {
		return error('Unsupported JSON value')
	}
}

fn native_json_struct[T](input T, inherited []string, prefix string) !json2.Any {
	mut values := map[string]json2.Any{}
	mut used := inherited.clone()
	$for field in T.fields {
		$if !field.is_embed {
			mut key := field.name
			mut skip := false
			for attr in field.attrs {
				if attr == 'skip' { skip = true }
				if attr.starts_with('json:') {
					key = attr.all_after('json:').trim_space().trim('\'"')
					if key == '-' { skip = true }
				}
			}
			if !skip && native_json_field_included(input.$(field.name), field.attrs) {
				output_key := if key in inherited { prefix + key } else { key }
				values[output_key] = native_json_value(input.$(field.name))!
				used << key
			}
		}
	}
	$for field in T.fields {
		$if field.is_embed {
			embedded := native_json_struct(input.$(field.name), used, prefix + field.name + '.')!
			for key, value in embedded.as_map() {
				values[key] = value
				used << key
			}
		}
	}
	return json2.Any(values)
}

fn native_json_optional_value[T](input ?T) !json2.Any {
	value := input or { return json2.Null{} }
	return native_json_value(value)
}

fn native_json_field_included[T](value T, attrs []string) bool {
	$if T is $option {
		if native_json_option_none(value) { return 'required' in attrs || 'json_null' in attrs }
	}
	$if T is $pointer {
		if value == unsafe { nil } { return false }
	}
	if 'omitempty' in attrs { return !native_json_empty[T](value) }
	return true
}

fn native_json_empty[T](value T) bool {
	$if T is $option {
		return native_json_optional_empty(value)
	} $else $if T is $pointer {
		return value == unsafe { nil }
	} $else $if T is string {
		return value.len == 0
	} $else $if T is $int || T is $float {
		return value == 0
	} $else $if T is $array || T is $map {
		return value.len == 0
	}
	return false
}

fn native_json_optional_empty[T](input ?T) bool {
	value := input or { return true }
	return native_json_empty[T](value)
}

fn native_json_option_none[T](input ?T) bool {
	return input == none
}
