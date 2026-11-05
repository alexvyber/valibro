module valibro_test

import os
import time
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

@[heap]
struct StructJsonCalls {
mut:
	values []string
}

struct StructJsonHook {
	id    string
	kind  string
	calls &StructJsonCalls
}

pub fn (value StructJsonHook) to_json_value(key string) !types.Maybe[json2.Any] {
	mut calls := value.calls
	calls.values << 'H:' + value.id + ':' + key
	if value.kind == 'error' { return error('Nested hook failed') }
	if value.kind == 'omit' { return types.undefined_value[json2.Any]() }
	if value.kind == 'null' { return types.null_value[json2.Any]() }
	return types.some(json2.Any({
		'id':     json2.Any(value.id)
		'key':    json2.Any(key)
		'answer': json2.Any(42)
	}))
}

struct StructJsonChild {
	hook     StructJsonHook @[json: 'renamed']
	skipped  StructJsonHook @[skip]
	ignored  StructJsonHook @[json: '-']
	empty    string         @[omitempty]
	absent   ?string
	nullable ?string @[json_null]
	required ?int    @[required]
	note     string = 'note'
}

struct StructJsonRoot {
	fixed       [1]StructJsonChild
	empty_list  []string       @[omitempty]
	empty_map   map[string]int @[omitempty]
	nested      StructJsonChild
	list        []StructJsonChild
	lookup      map[string]StructJsonChild
	when        time.Time
	count       u16 = 7
	maybe       ?StructJsonHook
	optional    ?string
	drop        int @[omitempty]
	nil_pointer &int = unsafe { nil }
}

struct EmbeddedJsonFields {
	same     string = 'inner'
	embedded StructJsonHook
}

struct EmbeddedJsonRoot {
	EmbeddedJsonFields
	same string = 'outer'
	own  StructJsonHook
}

fn struct_json_child(id string, kind string, calls &StructJsonCalls) StructJsonChild {
	return StructJsonChild{
		required: none
		hook:     StructJsonHook{
			id:    id
			kind:  kind
			calls: calls
		}
		skipped:  StructJsonHook{
			id:    'SKIPPED'
			kind:  'error'
			calls: calls
		}
		ignored:  StructJsonHook{
			id:    'IGNORED'
			kind:  'error'
			calls: calls
		}
	}
}

fn struct_json_result[T](input T, placement string, config v.StringifyJsonConfig) types.SafeParseResult[string] {
	if placement == 'array' {
		mut items := []T{}
		items << input
		return v.safe_parse(v.pipe_to(v.unknown[[]T](),
			v.stringify_json_value_with_config[[]T](config)), items)
	}
	if placement == 'map' {
		mut items := map[string]T{}
		items['root'] = input
		return v.safe_parse(v.pipe_to(v.unknown[map[string]T](),
			v.stringify_json_value_with_config[map[string]T](config)), items)
	}
	return v.safe_parse(v.pipe_to(v.unknown[T](), v.stringify_json_value_with_config[T](config)),
		input)
}

struct CustomEncodedJson {
	ignored StructJsonHook
	calls   &StructJsonCalls
}

pub fn (value CustomEncodedJson) to_json() string {
	mut calls := value.calls
	calls.values << 'E'
	return '{"encoded":true}'
}

struct CustomEncodedJsonRoot {
	custom CustomEncodedJson
	count  int = 7
}

fn test_nested_struct_hooks_and_v_json_tags_match_valibot() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/json/struct_json_differential.json')) or { panic(err) }) or { panic(err) }).as_array()
	for raw in rows {
		row := raw.as_map()
		kind := row['kind']!.str()
		mut calls := &StructJsonCalls{}
		mut config := v.StringifyJsonConfig{}
		mut placement := 'root'
		if row['family']!.str() == 'nested' {
			placement = row['placement']!.str()
			mode := row['mode']!.str()
			if mode == 'whitelist' {
				config = v.StringifyJsonConfig{
					property_list: ['root', 'nested', 'renamed', 'id', 'key', 'answer', 'count',
						'nullable', 'required', 'maybe']
				}
			} else if mode != 'plain' {
				config = v.StringifyJsonConfig{
					replacer_with_presence: fn [mut calls, mode] (key string, value types.Maybe[json2.Any], context v.JsonReplacerContext) !types.Maybe[json2.Any] {
						calls.values << 'R:' + key
						if key == 'nested' && mode == 'omit_parent' {
							return types.undefined_value[json2.Any]()
						}
						if key == 'nested' && mode == 'replace_parent' { return types.some(json2.Any({
								'replaced': json2.Any(true)
							})) }
						if key == 'renamed' && mode == 'error_replacer' {
							return error('Nested replacer failed')
						}
						return value
					}
				}
			}
		}
		if row['family']!.str() == 'encoder' && row['mode']!.str() == 'whitelist' {
			config = v.StringifyJsonConfig{
				property_list: ['count']
			}
		}
		result := if row['family']!.str() == 'encoder' {
			struct_json_result(CustomEncodedJsonRoot{
				custom: CustomEncodedJson{
					ignored: StructJsonHook{
						id:    'IGNORED'
						kind:  'error'
						calls: calls
					}
					calls:   calls
				}
			}, placement, config)
		} else if row['family']!.str() == 'embedded' {
			struct_json_result(EmbeddedJsonRoot{
				EmbeddedJsonFields: EmbeddedJsonFields{
					embedded: StructJsonHook{
						id:    'embedded'
						kind:  kind
						calls: calls
					}
				}
				own:                StructJsonHook{
					id:    'own'
					kind:  kind
					calls: calls
				}
			}, placement, config)
		} else {
			present := row['present']!.bool()
			maybe := if present { ?StructJsonHook(StructJsonHook{
					id:    'maybe'
					kind:  kind
					calls: calls
				}) } else { none }
			optional := if present { ?string('present') } else { none }
			struct_json_result(StructJsonRoot{
				fixed:    [struct_json_child('fixed', kind, calls)]!
				nested:   struct_json_child('nested', kind, calls)
				list:     [struct_json_child('list', kind, calls)]
				lookup:   {
					'entry': struct_json_child('lookup', kind, calls)
				}
				when:     time.unix(0)
				maybe:    maybe
				optional: optional
			}, placement, config)
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
