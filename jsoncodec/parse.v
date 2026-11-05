module jsoncodec

import valibro.internal.number as numbers
import x.json2
import valibro.types

struct Node {
	value      json2.Any
	source     ?string
	properties map[string]Node
	elements   []Node
}

struct Scanner {
	input            string
	binary64_numbers bool
mut:
	index int
}

fn (mut scanner Scanner) whitespace() {
	for scanner.index < scanner.input.len && scanner.input[scanner.index] in [` `, `\t`, `\n`, `\r`] {
		scanner.index++
	}
}

fn (mut scanner Scanner) string_end() {
	scanner.index++
	for scanner.index < scanner.input.len {
		ch := scanner.input[scanner.index]
		scanner.index++
		if ch == `"` { return }
		if ch == `\\` { scanner.index++ }
	}
}

// The native decoder validates grammar first. This pass records source spans
// and child nodes for the reviver's primitive source context.
fn (mut scanner Scanner) node() !Node {
	scanner.whitespace()
	start := scanner.index
	if scanner.index >= scanner.input.len { return error('Unexpected end of JSON') }
	if scanner.input[scanner.index] == `{` {
		scanner.index++
		mut children := map[string]Node{}
		mut object := map[string]json2.Any{}
		scanner.whitespace()
		for scanner.index < scanner.input.len && scanner.input[scanner.index] != `}` {
			key_start := scanner.index
			scanner.string_end()
			key := json2.decode[string](scanner.input[key_start..scanner.index])!
			scanner.whitespace()
			scanner.index++
			child := scanner.node()!
			children[key] = child
			object[key] = child.value
			scanner.whitespace()
			if scanner.input[scanner.index] != `,` { break
			 }
			scanner.index++
			scanner.whitespace()
		}
		scanner.index++
		return Node{
			value:      json2.Any(object)
			properties: children
		}
	}
	if scanner.input[scanner.index] == `[` {
		scanner.index++
		mut children := []Node{}
		mut array := []json2.Any{}
		scanner.whitespace()
		for scanner.index < scanner.input.len && scanner.input[scanner.index] != `]` {
			child := scanner.node()!
			children << child
			array << child.value
			scanner.whitespace()
			if scanner.index < scanner.input.len && scanner.input[scanner.index] == `,` {
				scanner.index++
			}
		}
		scanner.index++
		return Node{
			value:    json2.Any(array)
			elements: children
		}
	}
	if scanner.input[scanner.index] == `"` {
		scanner.string_end()
	} else {
		for scanner.index < scanner.input.len
			&& scanner.input[scanner.index] !in [`,`, `}`, `]`, ` `, `\t`, `\n`, `\r`] {
			scanner.index++
		}
	}
	token := scanner.input[start..scanner.index]
	if scanner.binary64_numbers && (token[0] == `-` || (token[0] >= `0` && token[0] <= `9`)) {
		return Node{
			value:  json2.Any(numbers.number_from_string(token)!)
			source: token
		}
	}
	decoded := json2.decode[json2.Any](token)!
	if decoded is f64 { return Node{
			value:  json2.Any(numbers.number_from_string(token)!)
			source: token
		} }
	return Node{
		value:  decoded
		source: token
	}
}

// Decode native JSON values without constructing reviver holder snapshots.
pub fn decode(input string) !json2.Any {
	root := decode_root(input, false)!
	return root.value
}

fn decode_root(input string, binary64_numbers bool) !Node {
	if binary64_numbers {
		validate_binary64_json(input)!
	} else {
		json2.decode[json2.Any](input)!
	}
	mut scanner := Scanner{
		input:            input
		binary64_numbers: binary64_numbers
	}
	return scanner.node()
}

pub fn parse(input string, config ParseConfig) !types.Maybe[json2.Any] {
	root := decode_root(input, config.binary64_numbers)!
	return revive('', root, json2.Any({
		'': root.value
	}), config)
}

fn revive(key string, node Node, holder json2.Any, config ParseConfig) !types.Maybe[json2.Any] {
	mut value := node.value
	if value is map[string]json2.Any {
		mut object := value.clone()
		for name in node.properties.keys() {
			child := node.properties[name] or { continue }
			result := revive(name, child, json2.Any(object.clone()), config)!
			match result.state {
				.missing, .undefined { object.delete(name) }
				.null { object[name] = json2.Null{} }
				.value { object[name] = result.value }
			}
		}
		value = json2.Any(object)
	} else if value is []json2.Any {
		mut array := value.clone()
		for i, child in node.elements {
			result := revive(i.str(), child, json2.Any(array.clone()), config)!
			array[i] = if result.state == .value { result.value } else { json2.Any(json2.Null{}) }
		}
		value = json2.Any(array)
	}
	return config.reviver(key, value, ReviverContext{
		source: node.source
		holder: holder_with_value(holder, key, value)
	})
}

// JSON callbacks observe a snapshot, including earlier sibling replacements.
fn holder_with_value(holder json2.Any, key string, value json2.Any) json2.Any {
	match holder {
		map[string]json2.Any {
			mut object := holder.clone()
			object[key] = value
			return json2.Any(object)
		}
		[]json2.Any {
			mut array := holder.clone()
			array[key.int()] = value
			return json2.Any(array)
		}
		else {
			return holder
		}
	}
}

// Mask already-validated numeric tokens so V's structural JSON validator never
// narrows them to native integer ranges before binary64 conversion.
fn validate_binary64_json(input string) ! {
	mut masked := ''
	mut index := 0
	mut quoted := false
	for index < input.len {
		c := input[index]
		if quoted {
			masked += input[index..index + 1]
			index++
			if c == `\\` && index < input.len {
				masked += input[index..index + 1]
				index++
			} else if c == `"` {
				quoted = false
			}
			continue
		}
		if c == `"` {
			quoted = true
			masked += '"'
			index++
			continue
		}
		if c == `-` || (c >= `0` && c <= `9`) {
			start := index
			for index < input.len && input[index] !in [`,`, `}`, `]`, `:`, ` `, `\t`, `\n`, `\r`] {
				index++
			}
			token := input[start..index]
			if !valid_json_number(token) { return error('Invalid JSON number') }
			masked += '0'
			continue
		}
		masked += input[index..index + 1]
		index++
	}
	json2.decode[json2.Any](masked)!
}

fn valid_json_number(text string) bool {
	mut index := 0
	if text.len == 0 { return false }
	if text[index] == `-` { index++ }
	if index == text.len { return false }
	if text[index] == `0` {
		index++
	} else {
		if text[index] < `1` || text[index] > `9` { return false }
		for index < text.len && text[index] >= `0` && text[index] <= `9` {
			index++
		}
	}
	if index < text.len && text[index] == `.` {
		index++
		start := index
		for index < text.len && text[index] >= `0` && text[index] <= `9` {
			index++
		}
		if index == start { return false }
	}
	if index < text.len && text[index] in [`e`, `E`] {
		index++
		if index < text.len && text[index] in [`+`, `-`] { index++ }
		start := index
		for index < text.len && text[index] >= `0` && text[index] <= `9` {
			index++
		}
		if index == start { return false }
	}
	return index == text.len
}
