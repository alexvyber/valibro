module valibro_test

import valibro.tests.support
import math.big
import time
import os
import x.json2
import valibro as v
import valibro.types

struct ConversionOutcome {
	success bool
	output  string
	issues  []types.Issue
}

fn conversion_value[T](value ?T) T {
	return value or { panic('Missing converted value') }
}

fn conversion_outcome[T](schema types.Schema[string, T], input string, settings v.Config) ConversionOutcome {
	result := v.safe_parse_with_config[string, T](schema, input, settings)
	if !result.success { return ConversionOutcome{
			issues: result.issues
		} }
	value := conversion_value[T](result.output)
	mut output := ''
	$if T is time.Time {
		output = value.unix_milli().str()
	} $else $if T is big.Integer {
		output = value.str()
	} $else {
		output = support.reference_string[T](value)
	}
	return ConversionOutcome{
		success: true
		output:  output
	}
}

fn test_conversion_outputs_and_failures_against_valibot() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/primitives/conversion_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	mut failures := 0
	mut counts := map[string]int{}
	for raw in rows {
		row := raw.as_map()
		input := row['input']!.str()
		mode := row['mode']!.str()
		messages := if mode == 'factory' {
			[types.ErrorMessage('Factory message')]
		} else {
			[]types.ErrorMessage{}
		}
		settings := if mode == 'config' {
			v.Config{
				message: types.ErrorMessage('Config message')
			}
		} else {
			v.Config{}
		}
		action := row['action']!.str()
		mut config := v.ParseBooleanConfig{}
		has_config := row['boolean_config']! !is json2.Null
		if has_config {
			fields := row['boolean_config']!.as_map()
			config = v.ParseBooleanConfig{
				truthy: fields['truthy']!.as_array().map(it.str())
				falsy:  fields['falsy']!.as_array().map(it.str())
			}
		}
		result := match action {
			'toNumber' {
				conversion_outcome[f64](v.pipe_to(v.string(), v.to_number(...messages)), input,
					settings)
			}
			'toBigint' {
				conversion_outcome[big.Integer](v.pipe_to(v.string(), v.to_bigint(...messages)),
					input, settings)
			}
			'toBoolean' {
				conversion_outcome[bool](v.pipe_to(v.string(), v.to_boolean()), input, settings)
			}
			'parseBoolean' {
				transform := if has_config {
					v.parse_boolean_with_config(config, ...messages)
				} else {
					v.parse_boolean(...messages)
				}
				conversion_outcome[bool](v.pipe_to(v.string(), transform), input, settings)
			}
			'toDate' {
				conversion_outcome[time.Time](v.pipe_to(v.string(), v.to_date(...messages)), input,
					settings)
			}
			else {
				panic(action)
			}
		}

		mut reason := ''
		if result.success != row['success']!.bool() {
			reason = 'success'
		} else if result.success {
			if result.output != row['output']!.str() { reason = 'output' }
		} else {
			issue := result.issues[0]
			if issue.expected != row['expected']!.str() {
				reason = 'expected'
			} else if issue.received != row['received']!.str() {
				reason = 'received'
			} else if issue.message != row['message']!.str() {
				reason = 'message'
			} else if issue.code != row['code']!.str() {
				reason = 'code'
			}
		}
		if reason != '' {
			failures++
			counts[action + ':' + reason]++
			if failures <= 10 { eprintln('${reason}: ${row}; got ${result}') }
		}
	}
	assert failures == 0, '${failures} mismatches: ${counts}'
}
