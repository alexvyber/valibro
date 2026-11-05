module valibro_test

import valibro.tests.support
import os
import time
import math.big
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

struct RawAuditInput {
	a string
	b string
}

struct RawAuditOutput {
	a big.Integer
	b big.Integer
}

fn raw_tag(kind string, value string) json2.Any {
	return json2.Any({
		'type':  json2.Any(kind)
		'value': json2.Any(value)
	})
}

fn raw_audit_encode(raw types.NativeValue, domain string) json2.Any {
	if types.value_is[string](raw) { return raw_tag('string', types.value_as[string](raw) or {
			panic(err)}) }
	if types.value_is[bool](raw) { return raw_tag('boolean', (types.value_as[bool](raw) or {
			panic(err)}).str()) }
	if types.value_is[f64](raw) { return raw_tag('number', support.reference_number_string(types.value_as[f64](raw) or {
			panic(err)})) }
	if types.value_is[big.Integer](raw) { return raw_tag('bigint', (types.value_as[big.Integer](raw) or {
			panic(err)}).str()) }
	if types.value_is[time.Time](raw) { return raw_tag('date', (types.value_as[time.Time](raw) or {
			panic(err)}).unix_milli().str()) }
	if types.value_is[types.InvalidDate](raw) { return raw_tag('date', 'invalid-date') }
	if types.value_is[json2.Any](raw) { return raw_audit_json(types.value_as[json2.Any](raw) or {
			panic(err)}) }
	mut items := []types.NativeValue{}
	mut kind := 'array'
	mut entries := []types.RawEntry{}
	if types.value_is[types.RawArray](raw) {
		items = (types.value_as[types.RawArray](raw) or { panic(err) }).items.clone()
	} else if types.value_is[types.RawSet](raw) {
		kind = 'set'
		items = (types.value_as[types.RawSet](raw) or { panic(err) }).items.clone()
	} else if types.value_is[[]big.Integer](raw) {
		for item in types.value_as[[]big.Integer](raw) or { panic(err) } {
			items << types.value_of(item)
		}
	} else if types.value_is[[][]big.Integer](raw) {
		for item in types.value_as[[][]big.Integer](raw) or { panic(err) } {
			items << types.value_of(item)
		}
	} else if types.value_is[types.Set[big.Integer]](raw) {
		kind = 'set'
		view := types.value_as[types.Set[big.Integer]](raw) or { panic(err) }
		for item in view.values {
			items << types.value_of(item)
		}
	} else if types.value_is[types.RawMap](raw) {
		kind = 'map'
		entries = (types.value_as[types.RawMap](raw) or { panic(err) }).entries.clone()
	} else if types.value_is[types.RawObject](raw) {
		kind = 'object'
		entries = (types.value_as[types.RawObject](raw) or { panic(err) }).entries.clone()
	} else if types.value_is[map[string]big.Integer](raw) {
		kind = if domain == 'map' { 'map' } else { 'object' }
		view := types.value_as[map[string]big.Integer](raw) or { panic(err) }
		for key, value in view {
			entries << types.RawEntry{
				key:   types.value_of(key)
				value: types.value_of(value)
			}
		}
	} else if types.value_is[types.RawStruct[RawAuditOutput]](raw) {
		kind = 'object'
		view := types.value_as[types.RawStruct[RawAuditOutput]](raw) or { panic(err) }
		for key in view.keys {
			value := view.fields[key] or {
				if key == 'a' { types.value_of(view.value.a) } else { types.value_of(view.value.b) }
			}
			entries << types.RawEntry{
				key:   types.value_of(key)
				value: value
			}
		}
	} else if types.value_is[RawAuditOutput](raw) {
		kind = 'object'
		view := types.value_as[RawAuditOutput](raw) or { panic(err) }
		entries = [
			types.RawEntry{
				key:   types.value_of('a')
				value: types.value_of(view.a)
			},
			types.RawEntry{
				key:   types.value_of('b')
				value: types.value_of(view.b)
			},
		]
	} else {
		panic('Unexpected raw native output')
	}
	if kind in ['map', 'object'] {
		mut result := []json2.Any{}
		for entry in entries {
			result << json2.Any([raw_audit_encode(entry.key, ''),
				raw_audit_encode(entry.value, '')])
		}
		return json2.Any({
			'type':    json2.Any(kind)
			'entries': json2.Any(result)
		})
	}
	mut result := []json2.Any{}
	for item in items {
		result << raw_audit_encode(item, '')
	}
	return json2.Any({
		'type':  json2.Any(kind)
		'items': json2.Any(result)
	})
}

fn raw_audit_json(value json2.Any) json2.Any {
	match value {
		string {
			return raw_tag('string', value)
		}
		bool {
			return raw_tag('boolean', value.str())
		}
		json2.Null {
			return json2.Any({
				'type': json2.Any('null')
			})
		}
		map[string]json2.Any {
			mut entries := []json2.Any{}
			for key, item in value {
				entries << json2.Any([raw_tag('string', key),
					raw_audit_json(item)])
			}
			return json2.Any({
				'type':    json2.Any('object')
				'entries': json2.Any(entries)
			})
		}
		[]json2.Any {
			mut items := []json2.Any{}
			for item in value {
				items << raw_audit_json(item)
			}
			return json2.Any({
				'type':  json2.Any('array')
				'items': json2.Any(items)
			})
		}
		else {
			return raw_tag('number', value.str())
		}
	}
}

fn raw_audit_check[T](result support.Observation[T], row map[string]json2.Any) {
	assert result.success == (row['success'] or { panic('missing success') }).bool(), row.str()
	assert result.typed == (row['typed'] or { panic('missing typed') }).bool(), row.str()
	actual := raw_audit_encode(result.raw_output,
		(row['family'] or { panic('missing family') }).str())
	assert j.equal(actual, (row['raw'] or { panic('missing raw') })), '${row}: ${actual}'
	if !result.success {
		missing := result.output == none
		assert missing
	}
}

fn test_failure_outputs_survive_native_type_changes_and_nested_collections() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/composition/raw_output_audit_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		config := v.Config{
			abort_early: row['abort_early']!.bool()
		}
		family := row['family']!.str()
		if family == 'scalar' {
			input := row['input']!.str()
			match row['action']!.str() {
				'skipNumber' {
					raw_audit_check(support.observe(v.pipe_to(v.pipe(v.string(), v.trim(),
						v.min_length(3)), v.to_number()), input, config), row)
				}
				'toNumber' {
					raw_audit_check(support.observe(v.pipe_to(v.string(), v.to_number()), input,
						config), row)
				}
				'toBigint' {
					raw_audit_check(support.observe(v.pipe_to(v.string(), v.to_bigint()), input,
						config), row)
				}
				'toDate' {
					raw_audit_check(support.observe(v.pipe_to(v.string(), v.to_date()), input,
						config), row)
				}
				'parseBoolean' {
					raw_audit_check(support.observe(v.pipe_to(v.string(), v.parse_boolean()),
						input, config), row)
				}
				else {
					raw_audit_check(support.observe(v.pipe_to(v.string(), v.parse_json()), input,
						config), row)
				}
			}

			continue
		}
		input := row['input']!.as_array().map(it.str())
		item := v.pipe_to(v.string(), v.to_bigint())
		mut object := map[string]string{}
		for index, value in input {
			object[rune(`a` + index).str()] = value
		}
		match family {
			'array' {
				raw_audit_check(support.observe(v.array(item), input, config), row)
			}
			'nested' {
				raw_audit_check(support.observe(v.array(v.array(item)), [
					['1'],
					input,
				], config), row)
			}
			'record' {
				raw_audit_check(support.observe(v.record(v.string(), item), object, config), row)
			}
			'map' {
				raw_audit_check(support.observe(v.map_schema(v.string(), item), object, config),
					row)
			}
			'set' {
				raw_audit_check(support.observe(v.set(item), types.new_set(input), config), row)
			}
			else {
				schema := v.object_from(fn (input RawAuditInput) RawAuditOutput {
					return RawAuditOutput{ a: big.integer_from_int(0), b: big.integer_from_int(0) }
				}, [
					v.field('a', fn (input RawAuditInput) string {
						return input.a
					}, fn (output RawAuditOutput, value big.Integer) RawAuditOutput {
						return RawAuditOutput{
							...output
							a: value
						}
					}, item),
					v.field('b', fn (input RawAuditInput) string {
						return input.b
					}, fn (output RawAuditOutput, value big.Integer) RawAuditOutput {
						return RawAuditOutput{
							...output
							b: value
						}
					}, item),
				])
				raw_audit_check(support.observe(schema, RawAuditInput{
					a: input[0]
					b: input[1]
				}, config), row)
			}
		}
	}
	types.value_as[int](types.value_of('wrong type')) or {
		assert err.msg() == 'Native value has a different type'
		return
	}
	assert false
}
