module actions

import valibro.internal.diagnostics
import math.big
import time
import valibro.jsoncodec
import valibro.schemas
import valibro.types
import x.json2

// On strings, JSON.stringify returns a quoted JSON string.
pub fn stringify_json() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'stringify_json'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: json2.encode(input)
			}
		}
	}
}

pub fn stringify_json_value[T](messages ...types.ErrorMessage) types.Transformation[T, string] {
	return stringify_json_value_with_config[T](jsoncodec.StringifyConfig{}, ...messages)
}

pub fn stringify_json_value_with_config[T](config jsoncodec.StringifyConfig, messages ...types.ErrorMessage) types.Transformation[T, string] {
	text := custom_message(messages, '')
	return types.Transformation[T, string]{
		type_name: 'stringify_json'
		run:       fn [config, text] [T](input T) types.Dataset[string] {
			value := native_json_source[T](input) or {
				return conversion_failure_input[T, string](input, 'stringify_json', 'JSON', '',
					json_failure_received[T](input, err), text)
			}
			output := jsoncodec.stringify_source(value, config) or {
				return conversion_failure_input[T, string](input, 'stringify_json', 'JSON', '',
					json_failure_received[T](input, err), text)
			}
			return types.Dataset[string]{
				value: output
			}
		}
	}
}

fn native_json_value[T](input T, key string) !json2.Any {
	$if T is jsoncodec.JsonValueProvider {
		selected := input.to_json_value(key)!
		if selected.state in [.missing, .undefined] { return jsoncodec.UndefinedOutput{} }
		if selected.state == .null { return json2.Null{} }
		return selected.value
	} $else $if T is time.Time {
		date := schemas.date().run(input, types.Config{})
		if !date.typed { return json2.Null{} }
		return json2.Any(diagnostics.value_label(date.value))
	} $else $if T is json2.Any {
		return input
	} $else $if T is string || T is bool || T is f64 || T is f32 || T is int || T is i64 || T is u64 {
		return json2.Any(input)
	} $else $if T is isize {
		return json2.Any(i64(input))
	} $else $if T is usize {
		return json2.Any(u64(input))
	} $else $if T is types.Null {
		return json2.Null{}
	} $else $if T is types.Undefined || T is types.Symbol || T is $function {
		return jsoncodec.UndefinedOutput{}
	} $else $if T is big.Integer {
		return error('Do not know how to serialize a BigInt')
	} $else $if T is $array {
		mut output := []json2.Any{}
		for index, item in input {
			child := native_json_value(item, index.str()) or {
				if err is jsoncodec.UndefinedOutput {
					output << json2.Any(json2.Null{})
					continue
				}
				return err
			}
			output << child
		}
		return json2.Any(output)
	} $else $if T is $map {
		mut output := map[string]json2.Any{}
		for entry_key, item in input {
			child := native_json_value(item, entry_key.str()) or {
				if err is jsoncodec.UndefinedOutput { continue
				 }
				return err
			}
			output[entry_key.str()] = child
		}
		return json2.Any(output)
	} $else {
		return json2.decode[json2.Any](json2.encode(input))
	}
}

fn json_failure_received[T](input T, err IError) string {
	if err is jsoncodec.UndefinedOutput {
		$if T is types.Symbol {
			return 'symbol'
		} $else $if T is types.Undefined {
			return 'undefined'
		} $else $if T is $function {
			return 'Function'
		} $else {
			return diagnostics.issue_value[T](input)
		}
	}
	return '"' + err.msg() + '"'
}

fn native_json_source[T](input T) !jsoncodec.JsonSource {
	$if T is $pointer {
		if input == unsafe { nil } { return jsoncodec.JsonSource{
				value: json2.Any(json2.Null{})
			} }
	}
	$if T is $option {
		return native_json_optional_source(input)
	} $else $if T is types.NativeMaybe {
		return native_json_maybe_source[T](input)
	} $else $if T is jsoncodec.JsonValueProvider {
		return jsoncodec.JsonSource{
			value: json2.Any(map[string]json2.Any{})
			hook:  fn [input] [T](key string) !types.Maybe[json2.Any] {
				return input.to_json_value(key)
			}
		}
	} $else $if T is time.Time || T is types.Null || T is types.Undefined || T is types.Symbol
		|| T is big.Integer {
		return native_json_leaf[T](input)
	} $else $if T is $pointer {
		if input == unsafe { nil } { return jsoncodec.JsonSource{
				value: json2.Any(json2.Null{})
			} }
		return native_json_source(*input)
	} $else $if T is $array_fixed {
		mut values := []json2.Any{}
		mut children := map[string]jsoncodec.JsonSource{}
		for index in 0 .. input.len {
			child := native_json_source(input[index])!
			values << child.value
			children[index.str()] = child
		}
		return jsoncodec.JsonSource{
			value:    json2.Any(values)
			children: children
		}
	} $else $if T is $array {
		mut values := []json2.Any{}
		mut children := map[string]jsoncodec.JsonSource{}
		for index, item in input {
			child := native_json_source(item)!
			values << child.value
			children[index.str()] = child
		}
		return jsoncodec.JsonSource{
			value:    json2.Any(values)
			children: children
		}
	} $else $if T is $map {
		mut values := map[string]json2.Any{}
		mut children := map[string]jsoncodec.JsonSource{}
		for key, item in input {
			child := native_json_source(item)!
			if child.missing { continue
			 }
			values[key.str()] = child.value
			children[key.str()] = child
		}
		return jsoncodec.JsonSource{
			value:    json2.Any(values)
			children: children
		}
	} $else $if T is json2.JsonEncoder || T is json2.Encodable {
		return native_json_deferred[T](input, json2.Any(map[string]json2.Any{}))
	} $else $if T is $struct {
		return native_json_struct[T](input, []string{}, '')
	} $else {
		return native_json_leaf[T](input)
	}
}

fn native_json_leaf[T](input T) !jsoncodec.JsonSource {
	initial := native_json_value[T](input, '') or { json2.Any(json2.Null{}) }
	return native_json_deferred[T](input, initial)
}

fn native_json_deferred[T](input T, initial json2.Any) jsoncodec.JsonSource {
	return jsoncodec.JsonSource{
		to_json_applied: false
		value:           initial
		hook:            fn [input] [T](key string) !types.Maybe[json2.Any] {
			return types.some(native_json_value[T](input, key)!)
		}
	}
}

fn native_json_struct[T](input T, inherited []string, prefix string) !jsoncodec.JsonSource {
	mut values := map[string]json2.Any{}
	mut children := map[string]jsoncodec.JsonSource{}
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
				child := native_json_source(input.$(field.name))!
				if !child.missing {
					values[output_key] = child.value
					children[output_key] = child
					used << key
				}
			}
		}
	}
	$for field in T.fields {
		$if field.is_embed {
			embedded := native_json_struct(input.$(field.name), used, prefix + field.name + '.')!
			for key, child in embedded.children {
				values[key] = child.value
				children[key] = child
				used << key
			}
		}
	}
	return jsoncodec.JsonSource{
		value:    json2.Any(values)
		children: children
	}
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

fn native_json_optional_source[T](input ?T) !jsoncodec.JsonSource {
	value := input or { return jsoncodec.JsonSource{
		value: json2.Any(json2.Null{})
	} }

	return native_json_source[T](value)
}

fn native_json_optional_empty[T](input ?T) bool {
	value := input or { return true }
	return native_json_empty[T](value)
}

fn native_json_option_none[T](input ?T) bool {
	return input == none
}

fn native_json_maybe_source[T](input T) !jsoncodec.JsonSource {
	state := input.state
	if state == .null { return jsoncodec.JsonSource{
			value: json2.Any(json2.Null{})
		} }
	if state in [.missing, .undefined] {
		return jsoncodec.JsonSource{
			value:   json2.Any(json2.Null{})
			missing: state == .missing
			hook:    absent_native_json
		}
	}
	$for field in T.fields {
		$if field.name == 'value' { return native_json_source(input.$(field.name)) }
	}
	return error('Native Maybe has no value field')
}

fn absent_native_json(key string) !types.Maybe[json2.Any] {
	_ = key
	return types.undefined_value[json2.Any]()
}
