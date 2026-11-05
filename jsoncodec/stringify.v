module jsoncodec

import valibro.internal.date as dates
import valibro.internal.diagnostics
import valibro.internal.number as numbers
import math
import strings
import time
import x.json2
import valibro.types

pub struct UndefinedOutput {}

pub fn (err UndefinedOutput) msg() string {
	return 'JSON serialization produced undefined'
}

pub fn (err UndefinedOutput) code() int {
	return 1
}

// Native trees retain deferred toJSON hooks until their property is traversed.
pub type JsonSourceHook = fn (key string) !types.Maybe[json2.Any]

pub struct JsonSource {
pub:
	// Native identity projections set this false; actual toJSON hooks run once.
	to_json_applied bool = true
	missing         bool
	value           json2.Any = json2.Null{}
	hook            ?JsonSourceHook
	children        map[string]JsonSource
}

pub fn stringify_source(source JsonSource, config StringifyConfig) !string {
	return stringify_native(source, config)
}

struct StringifyFrame {
	input  json2.Any
	holder json2.Any
	key    string
	depth  int
mut:
	source  JsonSource
	started bool
	value   json2.Any
	keys    []string
	index   int
	count   int
	array   bool
}

pub fn stringify(input json2.Any, config StringifyConfig) !string {
	return stringify_source(JsonSource{ value: input }, config)
}

// UTF-16 is an explicit interoperability conversion after native serialization.
pub fn stringify_utf16(input json2.Any, config StringifyConfig) ![]u16 {
	return types.utf16_units(stringify(input, config)!)
}

fn stringify_native(source JsonSource, config StringifyConfig) !string {
	input := source.value
	if config.max_depth < 0 { return error('JSON serialization depth must be non-negative') }
	gap := indent_text(config.space)
	mut output := strings.new_builder(256)
	defer { unsafe { output.free() } }
	mut stack := [
		StringifyFrame{
			source: source
			input:  input
			holder: json2.Any({
				'': input
			})
		},
	]
	for stack.len > 0 {
		last := stack.len - 1
		frame := stack[last]
		if !frame.started {
			if config.max_depth > 0 && frame.depth > config.max_depth {
				return error('JSON serialization depth exceeded')
			}
			mut input_value := frame.input
			mut available := true
			if hook := frame.source.hook {
				hooked := hook(frame.key) or {
					if err is UndefinedOutput {
						types.undefined_value[json2.Any]()
					} else {
						return err
					}
				}
				available = hooked.state !in [.missing, .undefined]
				input_value = if hooked.state == .null {
					json2.Any(json2.Null{})
				} else {
					hooked.value
				}
				stack[last].source = JsonSource{}
			}
			// Date.toJSON runs before the replacer, including dates held in json2.Any.
			if (frame.source.hook == none || !frame.source.to_json_applied)
				&& input_value is time.Time {
				input_value = boxed_date_json(input_value)
			}

			mut selected := types.undefined_value[json2.Any]()
			if replacer := config.replacer_with_presence {
				present := if !available {
					types.undefined_value[json2.Any]()
				} else if input_value is json2.Null {
					types.null_value[json2.Any]()
				} else {
					types.some(input_value)
				}
				selected = replacer(frame.key, present, ReplacerContext{ holder: frame.holder })!
			} else if !available {
			} else if replacer := config.replacer_with_context {
				selected =
					replacer(frame.key, input_value, ReplacerContext{ holder: frame.holder })!
			} else {
				selected = config.replacer(frame.key, input_value)!
			}
			if selected.state in [.missing, .undefined] {
				if last == 0 { return UndefinedOutput{} }
				parent := stack[last - 1]
				if parent.array {
					emit_prefix(mut output, parent, frame.key, gap)
					output.write_string('null')
					stack[last - 1].count++
				}
				stack.delete_last()
				continue
			}
			mut value := if selected.state == .null {
				json2.Any(json2.Null{})
			} else {
				selected.value
			}
			// Values returned by the replacer do not run toJSON a second time.
			if value is time.Time { value = boxed_date_json(value) }
			if frame.source.children.len > 0 && value != input_value {
				stack[last].source = JsonSource{
					children: retained_source_children(frame.source.children, input_value, value)
				}
			}
			if last > 0 {
				emit_prefix(mut output, stack[last - 1], frame.key, gap)
				stack[last - 1].count++
			}
			if value is map[string]json2.Any {
				keys := if list := config.property_list {
					list
				} else {
					value.keys()
				}
				mut seen := []string{}
				for key in keys {
					if key !in seen && key in value { seen << key }
				}
				stack[last].started = true
				stack[last].value = value
				stack[last].keys = seen.clone()
				output.write_u8(`{`)
			} else if value is []json2.Any {
				stack[last].started = true
				stack[last].array = true
				stack[last].value = value
				output.write_u8(`[`)
			} else {
				output.write_string(scalar_token(value, config.binary64_numbers))
				stack.delete_last()
			}
			continue
		}
		if frame.array {
			values := frame.value.as_array()
			if frame.index < values.len {
				index := frame.index
				stack[last].index++
				stack << StringifyFrame{
					source: frame.source.children[index.str()] or {
						JsonSource{
							value: values[index]
						}
					}
					input:  values[index]
					holder: json2.Any(values.clone())
					key:    index.str()
					depth:  frame.depth + 1
				}
				continue
			}
		} else if frame.index < frame.keys.len {
			key := frame.keys[frame.index]
			stack[last].index++
			values := frame.value.as_map()
			stack << StringifyFrame{
				source: frame.source.children[key] or {
					JsonSource{
						value: values[key] or { continue }
					}
				}
				input:  values[key] or { continue }
				holder: json2.Any(values.clone())
				key:    key
				depth:  frame.depth + 1
			}
			continue
		}
		if gap.len > 0 && frame.count > 0 {
			output.write_u8(`\n`)
			emit_indent(mut output, gap, frame.depth)
		}
		output.write_u8(if frame.array { u8(`]`) } else { u8(`}`) })
		stack.delete_last()
	}
	return output.str()
}

fn emit_prefix(mut output strings.Builder, parent StringifyFrame, key string, gap string) {
	if parent.count > 0 { output.write_u8(`,`) }
	if gap.len > 0 {
		output.write_u8(`\n`)
		emit_indent(mut output, gap, parent.depth + 1)
	}
	if !parent.array {
		output.write_string(json2.encode(key))
		output.write_u8(`:`)
		if gap.len > 0 { output.write_u8(` `) }
	}
}

fn emit_indent(mut output strings.Builder, gap string, depth int) {
	for _ in 0 .. depth {
		output.write_string(gap)
	}
}

fn indent_text(space Indent) string {
	match space {
		int {
			return ' '.repeat(if space < 0 {
				0
			} else {
				space
			})
		}
		string {
			return space
		}
	}
}

fn scalar_token(value json2.Any, binary64_numbers bool) string {
	if binary64_numbers && types.is_json_number(value) {
		number := value.f64()
		if math.is_nan(number) || math.is_inf(number, 0) { return 'null' }
		return numbers.native_number_string(number)
	}
	match value {
		json2.Null {
			return 'null'
		}
		string {
			return json2.encode(value)
		}
		f64 {
			return if math.is_nan(value) || math.is_inf(value, 0) {
				'null'
			} else {
				numbers.native_number_string(value)
			}
		}
		f32 {
			return if math.is_nan(f64(value)) || math.is_inf(f64(value), 0) {
				'null'
			} else {
				numbers.native_f32_string(value)
			}
		}
		else {
			return value.str()
		}
	}
}

// Native JSON values use value semantics: retain source hooks only at unchanged keys/indices.
fn retained_source_children(children map[string]JsonSource, before json2.Any, after json2.Any) map[string]JsonSource {
	mut retained := map[string]JsonSource{}
	if before is map[string]json2.Any && after is map[string]json2.Any {
		for key, child in children {
			old := before[key] or { continue }
			current := after[key] or { continue }
			if kept := retained_source_child(child, old, current) { retained[key] = kept }
		}
	} else if before is []json2.Any && after is []json2.Any {
		for index, old in before {
			if index >= after.len { break
			 }
			key := index.str()
			if child := children[key] {
				if kept := retained_source_child(child, old, after[index]) { retained[key] = kept }
			}
		}
	}
	return retained
}

fn retained_source_child(child JsonSource, before json2.Any, after json2.Any) ?JsonSource {
	if before == after { return child }
	if child.children.len == 0 { return none }
	children := retained_source_children(child.children, before, after)
	if children.len == 0 { return none }
	return JsonSource{
		value:    after
		children: children
	}
}

fn boxed_date_json(value time.Time) json2.Any {
	date := dates.validated_native_date(value) or { return json2.Any(json2.Null{}) }
	return json2.Any(diagnostics.value_label(date))
}
