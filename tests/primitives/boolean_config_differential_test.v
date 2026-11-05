module valibro_test

import os
import math
import x.json2
import valibro as v
import valibro.types

fn boolean_fixture_value(value json2.Any) json2.Any {
	if value is map[string]json2.Any {
		if value['$number'] or { json2.Any('') } == json2.Any('NaN') { return json2.Any(math.nan()) }
	}
	return value
}

fn test_configured_boolean_values_normalization_and_same_value_zero() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/primitives/boolean_config_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		positives := row['truthy']!.as_array().map(boolean_fixture_value(it))
		negatives := row['falsy']!.as_array().map(boolean_fixture_value(it))
		result := types.run_transformation(v.parse_boolean_with_values[json2.Any](positives,
			negatives), boolean_fixture_value(row['input']!))
		assert (result.issues.len == 0) == row['success']!.bool(), row.str()
		if result.issues.len == 0 {
			assert result.value == row['output']!.bool(), row.str()
		} else {
			expected := row['issues']!.as_array()[0].as_map()
			issue := result.issues[0]
			assert issue.expected == expected['expected']!.str(), row.str()
			assert issue.received == expected['received']!.str(), row.str()
			assert issue.message == expected['message']!.str(), row.str()
		}
	}
}
