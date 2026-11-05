module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

struct AuditMapKey {
	code     string
	original string
}

fn audit_map_equal(left AuditMapKey, right AuditMapKey) bool {
	return left.code == right.code
}

fn audit_key_json(key AuditMapKey) json2.Any {
	return json2.Any({
		'code':     json2.Any(key.code)
		'original': json2.Any(key.original)
	})
}

fn test_arbitrary_native_keys_and_explicit_set_comparators_match_valibot() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/collections/entry_map_audit_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		mut entries := []types.MapEntry[AuditMapKey, f64]{}
		mut keys := []AuditMapKey{}
		for item in row['entries']!.as_array() {
			entry := item.as_array()
			code := entry[0].str()
			key := AuditMapKey{
				code:     code
				original: code
			}
			entries << types.MapEntry[AuditMapKey, f64]{
				key:   key
				value: entry[1].f64()
			}
			keys << key
		}
		item := v.pipe(v.custom[AuditMapKey](fn (key AuditMapKey) bool {
			return key.code != 'bad'
		}), v.transform[AuditMapKey](fn (key AuditMapKey) AuditMapKey {
			return AuditMapKey{ ...key, code: key.code.to_lower() }
		}))
		config := v.Config{
			abort_early: row['abort_early']!.bool()
		}
		mut typed := false
		mut output := []json2.Any{}
		mut issues := []v.Issue{}
		if row['family']!.str() == 'map' {
			schema := v.entry_map(item, v.pipe(v.number(), v.min_value(0.0)), audit_map_equal)
			result := types.run(schema, types.entry_map(entries, audit_map_equal), config)
			typed = result.typed
			issues = result.issues.clone()
			if raw_output := result.raw_value {
				raw_map := types.value_as[types.RawMap](raw_output) or { panic(err) }
				mut raw_json := []json2.Any{}
				for entry in raw_map.entries {
					key := types.value_as[AuditMapKey](entry.key) or { panic(err) }
					value := types.value_as[f64](entry.value) or { panic(err) }
					raw_json << json2.Any({
						'key':   audit_key_json(key)
						'value': json2.Any(value)
					})
				}
				assert j.equal(json2.Any(raw_json), row['output']!), '${row}: ${raw_json}'
			}
			for entry in result.value.entries {
				output << json2.Any({
					'key':   audit_key_json(entry.key)
					'value': json2.Any(entry.value)
				})
			}
		} else {
			result := types.run(v.set_with(item, audit_map_equal), types.new_set_with(keys,
				audit_map_equal), config)
			typed = result.typed
			issues = result.issues.clone()
			if raw_output := result.raw_value {
				raw_set := types.value_as[types.RawSet](raw_output) or { panic(err) }
				mut raw_json := []json2.Any{}
				for raw_item in raw_set.items {
					key := types.value_as[AuditMapKey](raw_item) or { panic(err) }
					raw_json << audit_key_json(key)
				}
				assert j.equal(json2.Any(raw_json), row['output']!), '${row}: ${raw_json}'
			}
			for key in result.value.values {
				output << audit_key_json(key)
			}
		}
		assert typed == row['typed']!.bool(), row.str()
		assert j.equal(json2.Any(output), row['output']!), '${row}: ${output}'
		mut details := []json2.Any{}
		for issue in issues {
			key := if row['family']!.str() == 'map' {
				types.value_as[AuditMapKey](issue.path_keys[0]) or { panic(err) }
			} else {
				AuditMapKey{
					code: ''
				}
			}
			code := if row['family']!.str() == 'map' { key.code } else { '' }
			details << json2.Any({
				'code':    json2.Any(issue.code)
				'message': json2.Any(issue.message)
				'key':     json2.Any(code)
				'type':    json2.Any(issue.path_types[0])
			})
			assert issue.dot_path_unavailable
		}
		// Set path keys are null in Valibot; compare native null markers separately.
		assert j.equal(json2.Any(details), row['issues']!), row.str()
		if row['family']!.str() == 'set' {
			for issue in issues {
				assert types.value_is[json2.Null](issue.path_keys[0])
			}
		}
		flat := v.flatten(issues)
		expected := row['flat']!.as_map()
		assert flat.root == expected['root']!.as_array().map(it.str())
		assert flat.other == expected['other']!.as_array().map(it.str()), row.str()
		assert flat.nested.len == 0
	}
}
