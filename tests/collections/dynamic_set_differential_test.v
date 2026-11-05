module valibro_test

import os
import math
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

fn set_fixture_value(value json2.Any) json2.Any {
	if value is map[string]json2.Any {
		text := value['$float'] or { panic('float') }
		return json2.Any(match text.str() {
			'NaN' { math.nan() }
			'Infinity' { math.inf(1) }
			'-Infinity' { math.inf(-1) }
			else { text.f64() }
		})
	}
	return value
}

fn set_fixture_output(value json2.Any) json2.Any {
	if value is f64 {
		if math.is_nan(value) { return json2.Any({
				'$float': json2.Any('NaN')
			}) }
		if math.is_inf(value, 0) { return json2.Any({
				'$float': json2.Any(if value > 0 {
					'Infinity'
				} else {
					'-Infinity'
				})
			})
		 }
	}
	return value
}

fn test_dynamic_scalar_set_equality_matches_upstream() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/collections/dynamic_set_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		input := row['input']!.as_array().map(set_fixture_value(it))
		native := types.new_set(input)
		result := v.parse(v.set(v.unknown[json2.Any]()), native) or { panic(err) }
		output := result.values.map(set_fixture_output(it))
		assert j.equal(json2.Any(output), row['output']!), '${row}: ${output}'
		for value in result.values {
			if value is f64 && value == 0 { assert !math.signbit(value)
			 }
		}
	}
}
