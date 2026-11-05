module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

@[heap]
struct InteractionCalls {
mut:
	values []string
}

@[heap]
struct InteractionHook {
	id    string
	kind  string
	calls &InteractionCalls
}

pub fn (value InteractionHook) to_json_value(key string) !types.Maybe[json2.Any] {
	mut calls := value.calls
	calls.values << 'H:' + value.id + ':' + key
	if value.kind == 'error' { return error('Interaction hook failed') }
	if value.kind == 'omit' { return types.undefined_value[json2.Any]() }
	return types.some(json2.Any({
		'id':  json2.Any(value.id)
		'key': json2.Any(key)
	}))
}

@[heap]
struct InteractionEncoder {
	calls &InteractionCalls
}

pub fn (value InteractionEncoder) to_json() string {
	mut calls := value.calls
	calls.values << 'E'
	return '{"encoded":true}'
}

struct InteractionObject {
	a   InteractionHook
	b   InteractionHook
	tag int
}

struct InteractionDeep[T] {
	branch    T
	untouched bool = true
}

struct InteractionWrapped[T] {
	inside T
}

struct InteractionPointerField[T] {
	item T
}

@[heap]
struct InteractionPointerBox[T] {
	value T
}

fn interaction_json_result[T](input T, config v.StringifyJsonConfig) types.SafeParseResult[string] {
	return v.safe_parse(v.pipe_to(v.unknown[T](), v.stringify_json_value_with_config[T](config)),
		input)
}

fn interaction_place[T](input T, placement string, config v.StringifyJsonConfig) types.SafeParseResult[string] {
	if placement == 'nested' {
		return interaction_json_result(InteractionWrapped[T]{ inside: input }, config)
	}
	return interaction_json_result[T](input, config)
}

fn interaction_pointer[T](input T, placement string, config v.StringifyJsonConfig) types.SafeParseResult[string] {
	if placement == 'array' {
		mut items := []T{}
		items << input
		return interaction_json_result(items, config)
	}
	if placement == 'map' {
		mut items := map[string]T{}
		items['item'] = input
		return interaction_json_result(items, config)
	}
	if placement == 'field' {
		return interaction_json_result(InteractionPointerField[T]{ item: input }, config)
	}
	result := interaction_json_result(input, config)
	if !result.success {
		stored := types.value_as[T](result.raw_output) or { panic(err) }
		assert voidptr(stored) == voidptr(input)
	}
	return result
}

fn test_json_parent_replacements_and_native_pointers_match_valibot() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/json/json_interaction_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		family := row['family']!.str()
		placement := row['placement']!.str()
		kind := row['kind']!.str()
		mode := row['mode']!.str()
		mut calls := &InteractionCalls{}
		config := v.StringifyJsonConfig{
			replacer_with_presence: fn [mut calls, mode, placement, family] (key string, present types.Maybe[json2.Any], context v.JsonReplacerContext) !types.Maybe[json2.Any] {
				calls.values << 'R:' + key
				if family == 'pointer' {
					if present.state == .null && mode == 'recover_null' {
						return types.some(json2.Any('recovered'))
					}
					if present.state == .null && mode == 'omit_null' {
						return types.undefined_value[json2.Any]()
					}
					return present
				}
				value := if present.state == .null { json2.Any(json2.Null{}) } else { present.value }
				target := if placement == 'root' { '' } else { 'inside' }
				if key == target {
					if family.starts_with('deep_') {
						mut parent := value.as_map().clone()
						parent['branch'] = interaction_parent_edit(mode, parent['branch'] or {
							panic('branch')
						})
						return types.some(json2.Any(parent))
					}
					return types.some(interaction_parent_edit(mode, value))
				}
				first := key == 'a' || key == '0'
				if first && mode == 'error_after_a' { return error('Interaction replacer failed') }
				return present
			}
		}
		result := if family == 'pointer' {
			nil_value := row['nil']!.bool()
			if kind == 'hook' {
				value := if nil_value { unsafe { &InteractionHook(nil) } } else { &InteractionHook{
						id:    'P'
						kind:  'value'
						calls: calls
					} }
				interaction_pointer(value, placement, config)
			} else if kind == 'json' {
				holder := &InteractionPointerBox[json2.Any]{
					value: json2.Any({
						'encoded': json2.Any(true)
					})
				}
				mut value := &holder.value
				if nil_value { value = unsafe { nil } }
				interaction_pointer(value, placement, config)
			} else {
				value := if nil_value { unsafe { &InteractionEncoder(nil) } } else { &InteractionEncoder{
						calls: calls
					} }
				interaction_pointer(value, placement, config)
			}
		} else {
			a := InteractionHook{
				id:    'A'
				kind:  kind
				calls: calls
			}
			b := InteractionHook{
				id:    'B'
				kind:  kind
				calls: calls
			}
			if family.ends_with('object') {
				input := InteractionObject{
					a: a
					b: b
				}
				if family.starts_with('deep_') {
					interaction_place(InteractionDeep[InteractionObject]{ branch: input },
						placement, config)
				} else {
					interaction_place(input, placement, config)
				}
			} else {
				input := [a, b]
				if family.starts_with('deep_') {
					interaction_place(InteractionDeep[[]InteractionHook]{ branch: input },
						placement, config)
				} else {
					interaction_place(input, placement, config)
				}
			}
		}
		assert result.success == row['success']!.bool(), row.str()
		assert (result.output or { '' }) == row['output']!.str(), '${row}: ${result.output or { '' }}'
		assert calls.values == row['calls']!.as_array().map(it.str()), '${row}: ${calls.values}'
		details := result.issues.map(json2.Any({
			'code':     json2.Any(it.code)
			'message':  json2.Any(it.message)
			'received': json2.Any(it.received)
		}))
		assert j.equal(json2.Any(details), row['issues']!), '${row}: ${details}'
	}
}

fn interaction_parent_edit(mode string, value json2.Any) json2.Any {
	if mode == 'replace_all' { return json2.Any({
			'done': json2.Any(true)
		}) }
	if value is map[string]json2.Any {
		mut copy := value.clone()
		if mode == 'add' { copy['tag'] = json2.Any(1) }
		if mode == 'remove_b' { copy.delete('b') }
		if mode == 'replace_a' { copy['a'] = json2.Any('changed') }
		if mode == 'reverse_keys' { copy = {
				'tag': value['tag'] or { panic('tag') }
				'b':   value['b'] or { panic('b') }
				'a':   value['a'] or { panic('a') }
			} }
		return json2.Any(copy)
	} else if value is []json2.Any {
		mut copy := value.clone()
		if mode == 'add' { copy << json2.Any(99) }
		if mode == 'remove_b' { copy = copy[..1].clone() }
		if mode == 'replace_a' { copy[0] = json2.Any('changed') }
		return json2.Any(copy)
	}
	return value
}
