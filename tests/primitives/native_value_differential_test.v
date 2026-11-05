module valibro_test

import valibro.tests.support
import valibro.internal.date as impl_date
import os
import math.big
import time
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

fn native_value_check[T](name string, requirement T, zero T, messages []types.ErrorMessage) types.Action[T] {
	return match name {
		'minValue' { v.min_value(requirement, ...messages) }
		'maxValue' { v.max_value(requirement, ...messages) }
		'gtValue' { v.gt_value(requirement, ...messages) }
		'ltValue' { v.lt_value(requirement, ...messages) }
		'value' { v.value(requirement, ...messages) }
		'notValue' { v.not_value(requirement, ...messages) }
		'values' { v.values([requirement, zero, requirement], ...messages) }
		else { v.not_values([requirement, zero, requirement], ...messages) }
	}
}

fn test_native_date_and_bigint_value_issues_match_upstream() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/primitives/native_value_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		mode := row['mode']!.str()
		action := row['action']!.str()
		messages := if mode == 'factory' {
			[types.ErrorMessage('Factory message')]
		} else {
			[]types.ErrorMessage{}
		}
		config := if mode == 'config' {
			v.Config{
				message: 'Config message'
			}
		} else {
			v.Config{}
		}
		mut issues := []v.Issue{}
		mut success := false
		if row['domain']!.str() == 'date' {
			input := impl_date.date_from_milliseconds(row['input']!.i64())
			requirement := impl_date.date_from_milliseconds(row['requirement']!.i64())
			zero := impl_date.date_from_milliseconds(0)
			result := support.observe(v.pipe(v.date(), native_value_check[time.Time](action,
				requirement, zero, messages)), input, config)
			issues = result.issues.clone()
			success = result.success
		} else {
			input := big.integer_from_string(row['input']!.str()) or { panic(err) }
			requirement := big.integer_from_string(row['requirement']!.str()) or { panic(err) }
			result := support.observe(v.pipe(v.bigint(), native_value_check[big.Integer](action,
				requirement, big.integer_from_int(0), messages)), input, config)
			issues = result.issues.clone()
			success = result.success
		}
		mut details := []json2.Any{}
		for issue in issues {
			details << json2.Any({
				'code':     json2.Any(issue.code)
				'expected': json2.Any(issue.expected)
				'received': json2.Any(issue.received)
				'message':  json2.Any(issue.message)
			})
		}
		assert success == row['success']!.bool(), row.str()
		assert j.equal(json2.Any(details), row['issues']!), '${row}: ${details}'
	}
}
