module valibro_test

import valibro.tests.support
import os
import x.json2
import valibro as v
import valibro.types
import valibro.jsoncodec
import valibro.json as j

struct NumberAuditCalls {
mut:
	values []json2.Any
}

fn test_ecmascript_json_numbers_large_tokens_source_and_validation_match_reference() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/json/json_number_audit_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		mut calls := &NumberAuditCalls{}
		config := v.ParseJsonConfig{
			binary64_numbers: true
			reviver:          fn [mut calls] (key string, value json2.Any, context jsoncodec.ReviverContext) !types.Maybe[json2.Any] {
				if source := context.source { calls.values << json2.Any({
						'key':    json2.Any(key)
						'source': json2.Any(source)
						'number': json2.Any(support.reference_string[json2.Any](value))
					}) }
				return types.some(value)
			}
		}
		parsed := types.run_transformation(v.parse_json_with_config(config), row['text']!.str())
		assert (parsed.issues.len == 0) == row['success']!.bool(), row.str()
		if parsed.issues.len > 0 { continue
		 }
		output := jsoncodec.stringify(parsed.value.value, v.StringifyJsonConfig{
			binary64_numbers: true
		}) or { panic(err) }
		expected_output := jsoncodec.parse(row['output']!.str(), v.ParseJsonConfig{
			binary64_numbers: true
		}) or { panic(err) }
		actual_output := jsoncodec.parse(output, v.ParseJsonConfig{ binary64_numbers: true }) or {
			panic(err)
		}
		assert j.equal(actual_output.value, expected_output.value), row.str()

		assert j.equal(json2.Any(calls.values), row['calls']!), row.str()
	}
	assert jsoncodec.stringify(json2.Any(u64(18446744073709551615)), v.StringifyJsonConfig{
		binary64_numbers: true
	}) or { panic(err) } == '1.8446744073709552e+19'
	assert jsoncodec.stringify(json2.Any(u64(18446744073709551615)), v.StringifyJsonConfig{}) or {
		panic(err)
	} == '18446744073709551615'
}
