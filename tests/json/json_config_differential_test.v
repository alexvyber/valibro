module valibro_test

import valibro.tests.support
import os
import math
import math.big
import time
import x.json2
import valibro as v
import valibro.json as j
import valibro.jsoncodec
import valibro.types

struct JsonCalls {
mut:
	parse     []json2.Any
	stringify []string
}

fn json_tagged(input json2.Any) json2.Any {
	if input is map[string]json2.Any {
		if tag := input['$number'] {
			return json2.Any(match tag.str() {
				'NaN' { math.nan() }
				'Infinity' { math.inf(1) }
				'-Infinity' { math.inf(-1) }
				else { -0.0 }
			})
		}
		mut output := map[string]json2.Any{}
		for key, value in input {
			output[key] = json_tagged(value)
		}
		return json2.Any(output)
	}
	if input is []json2.Any { return json2.Any(input.map(json_tagged(it))) }
	return input
}

fn double_json_number(input json2.Any) json2.Any {
	return match input {
		int { json2.Any(input * 2) }
		i64 { json2.Any(input * 2) }
		u64 { json2.Any(input * 2) }
		f64 { json2.Any(input * 2) }
		f32 { json2.Any(input * 2) }
		else { input }
	}
}

fn test_json_configuration_differential() {
	corpus := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/json/json_config_differential.json')) or { panic(err) }) or { panic(err) }).as_map()
	mut failures := 0
	for raw in corpus['parse']!.as_array() {
		row := raw.as_map()
		mode := row['mode']!.str()
		mut calls := &JsonCalls{}
		config := v.ParseJsonConfig{
			reviver: fn [mode, mut calls] (key string, value json2.Any, context v.JsonReviverContext) !types.Maybe[json2.Any] {
				calls.parse << json2.Any({
					'key':    json2.Any(key)
					'source': if source := context.source {
						json2.Any(source)
					} else {
						json2.Any(json2.Null{})
					}
				})
				if mode == 'rootUndefined' && key == '' { return types.undefined_value[json2.Any]() }
				if mode == 'delete' && (key == 'drop' || (value is string && value == 'drop')) {
					return types.undefined_value[json2.Any]()
				}
				if mode == 'double' { return types.some[json2.Any](double_json_number(value)) }
				if mode == 'source' {
					if source := context.source { return types.some[json2.Any](json2.Any(source)) }
				}
				return types.some[json2.Any](value)
			}
		}
		result := v.parse(v.pipe_to(v.string(), v.parse_json_with_config(config)),
			row['input']!.str()) or { panic('${row}: ${err}') }
		output := if result.state == .value { result.value } else { json2.Any(json2.Null{}) }
		if (result.state == .undefined) != row['undefined']!.bool()
			|| !j.equal(output, row['output']!) || !j.equal(json2.Any(calls.parse), row['calls']!) {
			failures++
			if failures < 8 {
				eprintln('Parse mismatch ${row}: got ${result}; calls ${calls.parse}')
			}
		}
	}
	for raw in corpus['stringify']!.as_array() {
		row := raw.as_map()
		mode := row['mode']!.str()
		mut calls := &JsonCalls{}
		space := row['space']!
		indent := match space {
			int { jsoncodec.Indent(space) }
			i64 { jsoncodec.Indent(int(space)) }
			f64 { jsoncodec.Indent(int(space)) }
			string { jsoncodec.Indent(space) }
			else { panic('space') }
		}

		mut config := v.StringifyJsonConfig{
			space: indent
		}
		if mode in ['list', 'emptyList'] {
			config = v.StringifyJsonConfig{
				space:         indent
				property_list: if mode == 'list' {
					['b', 'a', '2', 'a', 'nested']
				} else {
					[]string{}
				}
			}
		} else {
			config = v.StringifyJsonConfig{
				space:    indent
				replacer: fn [mode, mut calls] (key string, value json2.Any) !types.Maybe[json2.Any] {
					calls.stringify << key
					if mode == 'throw' && key == '' { return error('Replacer failed') }
					if mode == 'rootUndefined' && key == '' {
						return types.undefined_value[json2.Any]()
					}
					if mode == 'delete'
						&& (key in ['drop', 'a'] || (value is string && value == 'drop')) {
						return types.undefined_value[json2.Any]()
					}
					if mode == 'double' { return types.some[json2.Any](double_json_number(value)) }
					return types.some[json2.Any](value)
				}
			}
		}
		schema := v.pipe_to(v.unknown[json2.Any](), v.stringify_json_with_config(config))
		result := v.safe_parse(schema, json_tagged(row['input']!))
		output := result.output or { '' }
		success := row['success']!.bool()
		mismatch := result.success != success
			|| !support.equal_json_text(output, row['output']!.str())
			|| !j.equal(json2.Any(calls.stringify.map(json2.Any(it))), row['calls']!)
		mut issue_mismatch := false
		if !success && !result.success {
			issue := result.issues[0]
			issue_mismatch = issue.received != row['received']!.str()
				|| issue.message != row['message']!.str() || issue.code != row['code']!.str()
		}
		if mismatch || issue_mismatch {
			failures++
			if failures < 8 {
				eprintln('Stringify mismatch ${row}: got ${result}, calls ${calls.stringify}')
			}
		}
	}
	assert failures == 0, '${failures} JSON configuration mismatches'
}

fn test_default_json_stringify_uses_native_number_formatting() {
	for input, expected in {
		1e21: '1e+21'
		1e-7: '1e-07'
		1e-6: '1e-06'
		-0.0: '-0'
	} {
		schema := v.pipe_to(v.number(), v.stringify_json_value[f64]())
		assert v.parse(schema, input) or { panic(err) } == expected
	}
	for input in [math.nan(), math.inf(1), math.inf(-1)] {
		schema := v.pipe_to(v.unknown[f64](), v.stringify_json_value[f64]())
		assert v.parse(schema, input) or { panic(err) } == 'null'
	}
}

fn test_reviver_failures_produce_transformation_issues_and_respect_messages() {
	config := v.ParseJsonConfig{
		reviver: fn (key string, value json2.Any, context v.JsonReviverContext) !types.Maybe[json2.Any] {
			return error('Reviver failed')
		}
	}
	schema := v.pipe_to(v.string(), v.parse_json_with_config(config))
	result := v.safe_parse(schema, '1')
	assert !result.success
	assert result.issues[0].code == 'parse_json'
	assert result.issues[0].received == '"Reviver failed"'
	assert result.issues[0].message == 'Invalid JSON: Received "Reviver failed"'
	assert result.issues[0].kind == .transformation
	assert v.safe_parse_with_config(schema, '1', v.Config{ message: types.ErrorMessage('Custom') }).issues[0].message == 'Custom'
}

fn test_native_non_json_values_and_nested_nonfinite_json_numbers() {
	null_schema := v.pipe_to(v.null_schema(), v.stringify_json_value[types.Null]())
	assert v.parse(null_schema, types.Null{}) or { panic(err) } == 'null'
	undefined := v.pipe_to(v.undefined_schema(), v.stringify_json_value[types.Undefined]())
	assert v.safe_parse(undefined, types.Undefined{}).issues[0].received == 'undefined'
	symbol := v.pipe_to(v.symbol(), v.stringify_json_value[types.Symbol]())
	assert v.safe_parse(symbol, types.symbol('x')).issues[0].received == 'symbol'
	array := v.pipe_to(v.unknown[[]f64](), v.stringify_json_value[[]f64]())
	assert v.parse(array, [1.0, math.nan(), -0.0, math.inf(1)]) or { panic(err) } == '[1,null,-0,null]'
	object := v.pipe_to(v.unknown[map[string]f64](), v.stringify_json_value[map[string]f64]())
	assert v.parse(object, {
		'a': math.nan()
		'b': 1e21
	}) or { panic(err) } == '{"a":null,"b":1e+21}'
}

fn json_coercion_output[T](schema types.Schema[json2.Any, T], input json2.Any, config v.Config) ConversionJsonOutcome {
	result := v.safe_parse_with_config[json2.Any, T](schema, input, config)
	if !result.success {
		mut nan_output := false
		$if T is f64 {
			raw := types.run[json2.Any, T](schema, input, config)
			nan_output = math.is_nan(raw.value)
		}
		return ConversionJsonOutcome{
			issues:     result.issues
			nan_output: nan_output
		}
	}
	value := json_coercion_value[T](result.output)
	mut output := ''
	$if T is time.Time {
		output = value.unix_milli().str()
	} $else {
		output = support.reference_string[T](value)
	}
	return ConversionJsonOutcome{
		success: true
		output:  output
	}
}

struct ConversionJsonOutcome {
	nan_output bool
	success    bool
	output     string
	issues     []types.Issue
}

fn json_coercion_value[T](input ?T) T {
	return input or { panic('output') }
}

fn test_json_input_coercions_against_valibot() {
	old_timezone := os.getenv_opt('TZ')
	os.setenv('TZ', 'UTC', true)
	defer {
		if zone := old_timezone {
			os.setenv('TZ', zone, true)
		} else {
			os.unsetenv('TZ')
		}
	}
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/json/json_coercion_differential.json')) or { panic(err) }) or { panic(err) }).as_array()
	mut failures := 0
	for raw in rows {
		row := raw.as_map()
		input := json_tagged(row['input']!)
		mode := row['mode']!.str()
		messages := if mode == 'factory' {
			[types.ErrorMessage('Factory message')]
		} else {
			[]types.ErrorMessage{}
		}
		config := if mode == 'config' {
			v.Config{
				message: types.ErrorMessage('Config message')
			}
		} else {
			v.Config{}
		}
		result := match row['action']!.str() {
			'toNumber' {
				json_coercion_output[f64](v.pipe_to(v.unknown[json2.Any](),
					v.to_number_from[json2.Any](...messages)), input, config)
			}
			'toBigint' {
				json_coercion_output[big.Integer](v.pipe_to(v.unknown[json2.Any](),
					v.to_bigint_from[json2.Any](...messages)), input, config)
			}
			'toDate' {
				json_coercion_output[time.Time](v.pipe_to(v.unknown[json2.Any](),
					v.to_date_from[json2.Any](...messages)), input, config)
			}
			'toString' {
				json_coercion_output[string](v.pipe_to(v.unknown[json2.Any](),
					v.to_string_from[json2.Any](...messages)), input, config)
			}
			'parseBoolean' {
				json_coercion_output[bool](v.pipe_to(v.unknown[json2.Any](),
					v.parse_boolean_from[json2.Any](...messages)), input, config)
			}
			else {
				json_coercion_output[bool](v.pipe_to(v.unknown[json2.Any](),
					v.to_boolean_from[json2.Any]()), input, config)
			}
		}

		mut mismatch := result.success != row['success']!.bool()
			|| result.nan_output != row['nan_output']!.bool()
		if result.success {
			mismatch = mismatch || result.output != row['output']!.str()
		} else {
			issue := result.issues[0]
			mismatch = mismatch || issue.expected != row['expected']!.str()
				|| issue.received != row['received']!.str()
				|| issue.message != row['message']!.str() || issue.code != row['code']!.str()
		}
		if mismatch {
			failures++
			if failures <= 7 { eprintln('JSON coercion ${row}; got ${result}') }
		}
	}
	assert failures == 0, '${failures} JSON coercion mismatches'
}
