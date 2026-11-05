module valibro_test

import valibro.tests.support
import os
import math
import math.big
import time
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

fn maybe_conversion_value[T](value ?T) T {
	return value or { panic('output') }
}

fn maybe_conversion_result[T](result types.SafeParseResult[T]) (bool, bool, string, []types.Issue) {
	if !result.success { return false, result.typed, '', result.issues }
	value := maybe_conversion_value[T](result.output)
	$if T is time.Time {
		return true, result.typed, value.unix_milli().str(), result.issues
	} $else {
		return true, result.typed, support.reference_string[T](value), result.issues
	}
}

fn maybe_conversion_run[T](input T, action string, messages []types.ErrorMessage) (bool, bool, string, []types.Issue) {
	base := v.unknown[T]()
	match action {
		'toNumber' {
			return maybe_conversion_result(v.safe_parse(v.pipe_to(base,
				v.to_number_from[T](...messages)), input))
		}
		'toBigint' {
			return maybe_conversion_result(v.safe_parse(v.pipe_to(base,
				v.to_bigint_from[T](...messages)), input))
		}
		'toBoolean' {
			return maybe_conversion_result(v.safe_parse(v.pipe_to(base, v.to_boolean_from[T]()),
				input))
		}
		'toDate' {
			return maybe_conversion_result(v.safe_parse(v.pipe_to(base,
				v.to_date_from[T](...messages)), input))
		}
		'toString' {
			return maybe_conversion_result(v.safe_parse(v.pipe_to(base,
				v.to_string_from[T](...messages)), input))
		}
		else {
			return maybe_conversion_result(v.safe_parse(v.pipe_to(base,
				v.parse_boolean_from[T](...messages)), input))
		}
	}
}

fn maybe_conversion_assert(row map[string]json2.Any, success bool, typed bool, output string, issues []types.Issue) {
	assert success == (row['success'] or { panic('success') }).bool(), row.str()
	assert typed == (row['typed'] or { panic('typed') }).bool(), row.str()
	assert output == (row['output'] or { panic('output') }).str(), '${row}: ${output}'
	details := issues.map(json2.Any({
		'code':     json2.Any(it.code)
		'expected': json2.Any(it.expected)
		'received': json2.Any(it.received)
		'message':  json2.Any(it.message)
	}))
	assert j.equal(json2.Any(details), row['issues'] or { panic('issues') }), '${row}: ${details}'
}

fn maybe_conversion_case[T](row map[string]json2.Any, payload T) {
	state := (row['state'] or { panic('state') }).str()
	action := (row['action'] or { panic('action') }).str()
	messages := if (row['mode'] or { panic('mode') }).str() == 'factory' { [
			types.ErrorMessage('Factory message'),
		] } else { []types.ErrorMessage{} }
	mut input := types.Maybe[T]{}
	match state {
		'missing' { input = types.missing[T]() }
		'undefined' { input = types.undefined_value[T]() }
		'null' { input = types.null_value[T]() }
		else { input = types.some(payload) }
	}

	success, typed, output, issues := maybe_conversion_run(input, action, messages)
	maybe_conversion_assert(row, success, typed, output, issues)
	// Nested wrappers must have the same logical conversion behavior.
	nsuccess, ntyped, noutput, nissues := maybe_conversion_run(types.some(input), action, messages)
	maybe_conversion_assert(row, nsuccess, ntyped, noutput, nissues)
}

fn test_native_maybe_conversions_match_valibot() {
	old := os.getenv_opt('TZ')
	defer {
		if value := old {
			os.setenv('TZ', value, true)
		} else {
			os.unsetenv('TZ')
		}
	}
	os.setenv('TZ', 'UTC', true)
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/primitives/maybe_conversion_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		match row['kind']!.str() {
			'text' {
				maybe_conversion_case(row, '42')
			}
			'true_text' {
				maybe_conversion_case(row, 'TRUE')
			}
			'empty_text' {
				maybe_conversion_case(row, '')
			}
			'bad_text' {
				maybe_conversion_case(row, 'bad')
			}
			'zero' {
				maybe_conversion_case(row, 0.0)
			}
			'one' {
				maybe_conversion_case(row, 1.0)
			}
			'number' {
				maybe_conversion_case(row, 42.0)
			}
			'nan' {
				maybe_conversion_case(row, math.nan())
			}
			'yes' {
				maybe_conversion_case(row, true)
			}
			'no' {
				maybe_conversion_case(row, false)
			}
			'date' {
				maybe_conversion_case(row, time.unix(0))
			}
			'invalid_date' {
				maybe_conversion_case(row, time.Time{})
			}
			'bigint' {
				maybe_conversion_case(row, big.integer_from_int(42))
			}
			'array' {
				maybe_conversion_case(row, json2.Any([]json2.Any{}))
			}
			'object' {
				maybe_conversion_case(row, json2.Any({
					'n': json2.Any(1)
				}))
			}
			else {
				maybe_conversion_case(row, types.symbol('x'))
			}
		}
	}
}
