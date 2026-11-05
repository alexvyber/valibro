module valibro_test

import valibro.internal.date as impl_date
import valibro.tests.support
import os
import time
import math.big
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

@[heap]
struct BoxedDateCalls {
mut:
	values []string
}

struct BoxedDatePrimitive {
	value json2.Any
	calls &BoxedDateCalls
}

// This oracle adapter deliberately rejects a Date as a scalar conversion.
pub fn (value BoxedDatePrimitive) to_number() !f64 {
	mut calls := value.calls
	calls.values << 'number'
	return types.TypeError{
		message: 'Oracle provider rejects a Date scalar'
	}
}

pub fn (value BoxedDatePrimitive) to_bigint() !big.Integer {
	mut calls := value.calls
	calls.values << 'number'
	return types.TypeError{
		message: 'Oracle provider rejects a Date scalar'
	}
}

pub fn (value BoxedDatePrimitive) to_date() !time.Time {
	mut calls := value.calls
	calls.values << 'default'
	return types.TypeError{
		message: 'Oracle provider rejects a Date scalar'
	}
}

pub fn (value BoxedDatePrimitive) to_string() !string {
	mut calls := value.calls
	calls.values << 'string'
	return types.TypeError{
		message: 'Oracle provider rejects a Date scalar'
	}
}

// The oracle adapter explicitly chooses its own boolean conversion.
pub fn (value BoxedDatePrimitive) to_boolean() !bool {
	return true
}

fn boxed_date_unwrap[T](input ?T) T {
	return input or { panic('output') }
}

fn boxed_date_result[T](result types.SafeParseResult[T]) (bool, bool, string, []types.Issue) {
	if !result.success { return false, result.typed, '', result.issues }
	value := boxed_date_unwrap[T](result.output)
	$if T is time.Time {
		return true, result.typed, value.unix_milli().str(), result.issues
	} $else {
		return true, result.typed, support.reference_string[T](value), result.issues
	}
}

fn boxed_date_conversion[T](action string, input T, messages []types.ErrorMessage) (bool, bool, string, []types.Issue) {
	base := v.unknown[T]()
	match action {
		'toNumber' {
			return boxed_date_result(v.safe_parse(v.pipe_to(base, v.to_number_from[T](...messages)),
				input))
		}
		'toBigint' {
			return boxed_date_result(v.safe_parse(v.pipe_to(base, v.to_bigint_from[T](...messages)),
				input))
		}
		'toDate' {
			return boxed_date_result(v.safe_parse(v.pipe_to(base, v.to_date_from[T](...messages)),
				input))
		}
		'toString' {
			return boxed_date_result(v.safe_parse(v.pipe_to(base, v.to_string_from[T](...messages)),
				input))
		}
		'toBoolean' {
			return boxed_date_result(v.safe_parse(v.pipe_to(base, v.to_boolean_from[T]()), input))
		}
		else {
			return boxed_date_result(v.safe_parse(v.pipe_to(base,
				v.stringify_json_value[T](...messages)), input))
		}
	}
}

struct BoxedDateJsonProvider {
	value time.Time
	calls &BoxedDateCalls
}

pub fn (value BoxedDateJsonProvider) to_json_value(key string) !types.Maybe[json2.Any] {
	mut calls := value.calls
	calls.values << 'H:' + key
	return types.some(json2.Any(value.value))
}

fn boxed_date_provider_placed(input BoxedDateJsonProvider, placement string, config v.StringifyJsonConfig) types.SafeParseResult[string] {
	if placement == 'array' {
		return v.safe_parse(v.pipe_to(v.unknown[[]BoxedDateJsonProvider](),
			v.stringify_json_value_with_config[[]BoxedDateJsonProvider](config)), [
			input,
		])
	}
	if placement == 'map' {
		return v.safe_parse(v.pipe_to(v.unknown[map[string]BoxedDateJsonProvider](),
			v.stringify_json_value_with_config[map[string]BoxedDateJsonProvider](config)), {
			'a': input
		})
	}
	return v.safe_parse(v.pipe_to(v.unknown[BoxedDateJsonProvider](),
		v.stringify_json_value_with_config[BoxedDateJsonProvider](config)), input)
}

fn test_boxed_dates_match_valibot_conversions_and_json_phases() {
	old := os.getenv_opt('TZ')
	defer {
		if value := old {
			os.setenv('TZ', value, true)
		} else {
			os.unsetenv('TZ')
		}
	}
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/json/boxed_date_differential.json')) or { panic(err) }) or { panic(err) }).as_array()
	for raw in rows {
		row := raw.as_map()
		stamp := row['stamp']!
		date := if stamp is json2.Null {
			time.Time{}
		} else {
			impl_date.date_from_milliseconds(stamp.i64())
		}
		family := row['family']!.str()
		scalar := json2.Any(date)
		input := if family == 'conversion' && row['placement']!.str() == 'array' { json2.Any([
				scalar,
			]) } else { scalar }
		mut calls := &BoxedDateCalls{}
		if family in ['serialization', 'provider_date'] {
			os.setenv('TZ', 'UTC', true)
			placement := row['placement']!.str()
			mode := row['mode']!.str()
			mut config := v.StringifyJsonConfig{}
			if mode != 'plain' {
				config = v.StringifyJsonConfig{
					replacer_with_presence: fn [mut calls, mode, placement] (key string, value types.Maybe[json2.Any], context v.JsonReplacerContext) !types.Maybe[json2.Any] {
						kind := if value.state == .null {
							'null'
						} else if value.value is string {
							'string'
						} else {
							'object'
						}
						calls.values << key + ':' + kind
						target := if placement == 'root' { key == '' } else { key in [
								'a',
								'0',
							] }
						if target && mode == 'replace_with_date' {
							return types.some(json2.Any(time.unix(0)))
						}
						if target && mode == 'replace_with_null' {
							return types.null_value[json2.Any]()
						}
						if target && mode == 'omit_dates' {
							return types.undefined_value[json2.Any]()
						}
						if value.state == .null && mode == 'recover_null' {
							return types.some(json2.Any('recovered'))
						}
						return value
					}
				}
			}
			value := if placement == 'array' {
				json2.Any([input])
			} else if placement == 'map' {
				json2.Any({
					'a': input
				})
			} else {
				input
			}
			// Both the native adapter and the direct JSON codec must have identical phases.
			for direct in [false, true] {
				if direct && family == 'provider_date' { continue
				 }
				calls.values.clear()
				result := if family == 'provider_date' {
					boxed_date_provider_placed(BoxedDateJsonProvider{ value: date, calls: calls },
						placement, config)
				} else if direct {
					v.safe_parse(v.pipe_to(v.unknown[json2.Any](),
						v.stringify_json_with_config(config)), value)
				} else {
					v.safe_parse(v.pipe_to(v.unknown[json2.Any](),
						v.stringify_json_value_with_config[json2.Any](config)), value)
				}
				assert result.success == row['success']!.bool(), row.str()
				assert (result.output or { '' }) == row['output']!.str(), '${row}: ${result.output or {
					''
				}}'

				assert calls.values == row['calls']!.as_array().map(it.str()), '${row}: ${calls.values}'
				details := result.issues.map(json2.Any({
					'code':     json2.Any(it.code)
					'received': json2.Any(it.received)
					'message':  json2.Any(it.message)
				}))
				assert j.equal(json2.Any(details), row['issues']!), '${row}: ${details}'
			}
			continue
		}
		if family == 'conversion' { os.setenv('TZ', row['timezone']!.str(), true) }
		messages := if family == 'conversion' && row['mode']!.str() == 'factory' { [
				types.ErrorMessage('Factory message'),
			] } else { []types.ErrorMessage{} }
		success, typed, output, issues := if family == 'primitive' {
			boxed_date_conversion(row['action']!.str(), BoxedDatePrimitive{
				value: input
				calls: calls
			}, messages)
		} else {
			boxed_date_conversion(row['action']!.str(), input, messages)
		}
		assert success == row['success']!.bool(), row.str()
		assert support.equal_json_text(output, row['output']!.str()), '${row}: ${output}'
		if family == 'conversion' { assert typed == row['typed']!.bool(), row.str()
		 }
		mut details := []json2.Any{}
		for issue in issues {
			mut detail := {
				'code':     json2.Any(issue.code)
				'received': json2.Any(issue.received)
				'message':  json2.Any(issue.message)
			}
			if family == 'conversion' { detail['expected'] = json2.Any(issue.expected) }
			details << json2.Any(detail)
		}
		assert j.equal(json2.Any(details), row['issues']!), '${row}: ${details}'
		if family == 'primitive' { assert calls.values == row['calls']!.as_array().map(it.str()), '${row}: ${calls.values}'
		 }
	}
}
