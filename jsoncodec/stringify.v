module jsoncodec

import valibro.internal.date as dates
import valibro.internal.diagnostics
import valibro.internal.number as numbers
import valibro.types
import math
import strings
import time
import x.json2

struct StringifyFrame {
	input json2.Any
	key   string
	depth int
mut:
	started bool
	value   json2.Any
	keys    []string
	index   int
	count   int
	array   bool
}

// Serialize JSON values with native integer precision and UTF-8 output.
pub fn stringify(input json2.Any, config StringifyConfig) !string {
	if config.max_depth < 0 { return error('JSON serialization depth must be non-negative') }
	gap := indent_text(config.space)
	mut output := strings.new_builder(256)
	defer { unsafe { output.free() } }
	mut stack := [StringifyFrame{ input: input }]
	for stack.len > 0 {
		last := stack.len - 1
		frame := stack[last]
		if !frame.started {
			if config.max_depth > 0 && frame.depth > config.max_depth {
				return error('JSON serialization depth exceeded')
			}
			mut value := frame.input
			if value is time.Time { value = boxed_date_json(value) }
			if last > 0 {
				emit_prefix(mut output, stack[last - 1], frame.key, gap)
				stack[last - 1].count++
			}
			if value is map[string]json2.Any {
				stack[last].started = true
				stack[last].value = value
				stack[last].keys = value.keys()
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
					input: values[index]
					key:   index.str()
					depth: frame.depth + 1
				}
				continue
			}
		} else if frame.index < frame.keys.len {
			key := frame.keys[frame.index]
			stack[last].index++
			values := frame.value.as_map()
			stack << StringifyFrame{
				input: values[key] or { continue }
				key:   key
				depth: frame.depth + 1
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

fn boxed_date_json(value time.Time) json2.Any {
	date := dates.validated_native_date(value) or { return json2.Any(json2.Null{}) }
	return json2.Any(diagnostics.value_label(date))
}
