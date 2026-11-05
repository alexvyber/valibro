module valibro_test

import valibro.internal.date as impl_date
import os
import time
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

fn native_date_validation_tag(input time.Time) string {
	value := impl_date.validated_native_date(input) or { return 'invalid' }
	return value.unix_milli().str()
}

fn native_date_validation_check[T](row map[string]json2.Any, result types.SafeParseResult[T]) {
	assert result.success == (row['success'] or { panic('success') }).bool(), row.str()
	assert result.typed == (row['typed'] or { panic('typed') }).bool(), row.str()
	mut output := json2.Any(json2.Null{})
	if types.value_is[time.Time](result.raw_output) {
		output = json2.Any(native_date_validation_tag(types.value_as[time.Time](result.raw_output) or {
			panic(err)
		}))
	} else {
		values := types.value_as[[]time.Time](result.raw_output) or { panic(err) }
		output = json2.Any(values.map(json2.Any(native_date_validation_tag(it))))
	}
	assert j.equal(output, row['output'] or { panic('output') }), '${row}: ${output}'
	details := result.issues.map(json2.Any({
		'code':     json2.Any(it.code)
		'kind':     json2.Any(it.kind.str())
		'expected': json2.Any(it.expected)
		'received': json2.Any(it.received)
		'message':  json2.Any(it.message)
		'dot':      json2.Any(v.get_dot_path(it))
	}))
	assert j.equal(json2.Any(details), row['issues'] or { panic('issues') }), '${row}: ${details}'
}

fn test_native_date_validation_issues_match_valibot() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/primitives/native_date_validation_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	base := time.new(time.Time{ year: 2024, month: 2, day: 29 })
	for raw in rows {
		row := raw.as_map()
		mut input := time.Time{}
		if stamp := row['stamp'] {
			input = impl_date.date_from_milliseconds(stamp.i64())
		} else if row['name']!.str() != 'zero' {
			fields := row['fields']!.as_map()
			input = time.Time{
				...base
				year:       if value := fields['year'] { value.int() } else { base.year }
				month:      if value := fields['month'] { value.int() } else { base.month }
				day:        if value := fields['day'] { value.int() } else { base.day }
				hour:       if value := fields['hour'] { value.int() } else { base.hour }
				minute:     if value := fields['minute'] { value.int() } else { base.minute }
				second:     if value := fields['second'] { value.int() } else { base.second }
				nanosecond: if value := fields['nanosecond'] { value.int() } else { base.nanosecond }
			}
		}
		messages := if row['mode']!.str() == 'factory' { [
				types.ErrorMessage('Factory message'),
			] } else { []types.ErrorMessage{} }
		mut config := v.Config{
			abort_early:      row['abort_early']!.bool()
			abort_pipe_early: row['abort_pipe_early']!.bool()
		}
		if row['mode']!.str() == 'config' { config = v.Config{
				...config
				message: 'Config message'
			} }
		item := v.date(...messages)
		if row['placement']!.str() == 'root' {
			native_date_validation_check(row, v.safe_parse_with_config(item, input, config))
		} else {
			native_date_validation_check(row, v.safe_parse_with_config(v.array(item), [
				input,
				time.unix(0),
			], config))
		}
	}
}
