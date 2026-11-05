module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.jsoncodec

fn test_json_unbounded_depth_and_exact_utf16_output_match_valibot() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/json/json_runtime_audit_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		mut input := json2.Any(0)
		mut config := v.StringifyJsonConfig{}
		if row['family']!.str() == 'depth' {
			container := row['container']!.str()
			for i in 0 .. row['depth']!.int() {
				mixed_array := container == 'mixed' && i % 2 == 0
				input = if container == 'array' || mixed_array { json2.Any([
						input,
					]) } else { json2.Any({
						'x': input
					}) }
			}
		} else {
			input = row['input']!
			space := row['space']!
			indent := match space {
				string { jsoncodec.Indent(space) }
				else { jsoncodec.Indent(space.int()) }
			}

			config = v.StringifyJsonConfig{
				space: indent
			}
		}
		expected := row['output_units']!.as_array().map(u16(it.int()))
		result := types.run_transformation(v.stringify_json_with_config_utf16(config), input)
		assert result.issues.len == 0, row.str()
		assert result.value == expected, 'JSON runtime ${row['family'] or { panic('family') }}: ${result.value.len} != ${expected.len}'
		assert jsoncodec.stringify(input, config) or { panic(err) } == types.utf16_display(expected)
	}
	mut deep := json2.Any(1)
	for _ in 0 .. 40 {
		deep = json2.Any([deep])
	}
	jsoncodec.stringify(deep, v.StringifyJsonConfig{ max_depth: 32 }) or {
		assert err.msg() == 'JSON serialization depth exceeded'
		return
	}
	assert false, 'Explicit safety bound must be enforced'
}
