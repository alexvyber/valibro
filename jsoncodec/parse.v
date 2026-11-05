module jsoncodec

import valibro.internal.number as numbers
import x.json2

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

// Validate grammar first, then decode numeric tokens through the exact parser.
fn (mut scanner Scanner) node() !json2.Any {
	scanner.whitespace()
	start := scanner.index
	if scanner.index >= scanner.input.len { return error('Unexpected end of JSON') }
	if scanner.input[scanner.index] == `{` {
		scanner.index++
		mut object := map[string]json2.Any{}
		scanner.whitespace()
		for scanner.index < scanner.input.len && scanner.input[scanner.index] != `}` {
			key_start := scanner.index
			scanner.string_end()
			key := json2.decode[string](scanner.input[key_start..scanner.index])!
			scanner.whitespace()
			scanner.index++
			child := scanner.node()!
			object[key] = child
			scanner.whitespace()
			if scanner.input[scanner.index] != `,` { break
			 }
			scanner.index++
			scanner.whitespace()
		}
		scanner.index++
		return json2.Any(object)
	}
	if scanner.input[scanner.index] == `[` {
		scanner.index++
		mut array := []json2.Any{}
		scanner.whitespace()
		for scanner.index < scanner.input.len && scanner.input[scanner.index] != `]` {
			child := scanner.node()!
			array << child
			scanner.whitespace()
			if scanner.index < scanner.input.len && scanner.input[scanner.index] == `,` {
				scanner.index++
			}
		}
		scanner.index++
		return json2.Any(array)
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
		return json2.Any(numbers.number_from_string(token)!)
	}
	decoded := json2.decode[json2.Any](token)!
	if decoded is f64 { return json2.Any(numbers.number_from_string(token)!) }
	return decoded
}

// Decode JSON with exact ties-to-even float rounding.
pub fn decode(input string, config ParseConfig) !json2.Any {
	root := decode_root(input, config.binary64_numbers)!
	return root
}

fn decode_root(input string, binary64_numbers bool) !json2.Any {
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
