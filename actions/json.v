module actions

import valibro.internal.diagnostics
import valibro.jsoncodec
import valibro.types
import x.json2

pub fn parse_json(messages ...types.ErrorMessage) types.Transformation[string, json2.Any] {
	text := custom_message(messages, '')
	return types.Transformation[string, json2.Any]{
		type_name: 'parse_json'
		run:       fn [text] (input string) types.Dataset[json2.Any] {
			converted := jsoncodec.decode(input) or {
				return conversion_failure_input[string, json2.Any](input, 'parse_json', 'JSON', '',

					'"' + err.msg() + '"', text)
			}
			return types.Dataset[json2.Any]{
				value: converted
			}
		}
	}
}

pub fn parse_json_with_config(config jsoncodec.ParseConfig, messages ...types.ErrorMessage) types.Transformation[string, types.Maybe[json2.Any]] {
	text := custom_message(messages, '')
	return types.Transformation[string, types.Maybe[json2.Any]]{
		type_name: 'parse_json'
		run:       fn [config, text] (input string) types.Dataset[types.Maybe[json2.Any]] {
			output := jsoncodec.parse(input, config) or {
				return conversion_failure_input[string, types.Maybe[json2.Any]](input,
					'parse_json', 'JSON', '', '"' + err.msg() + '"', text)
			}
			return types.Dataset[types.Maybe[json2.Any]]{
				value: output
			}
		}
	}
}

pub fn stringify_json_with_config(config jsoncodec.StringifyConfig, messages ...types.ErrorMessage) types.Transformation[json2.Any, string] {
	text := custom_message(messages, '')
	return types.Transformation[json2.Any, string]{
		type_name: 'stringify_json'
		run:       fn [config, text] (input json2.Any) types.Dataset[string] {
			output := jsoncodec.stringify(input, config) or {
				mut received := '"' + err.msg() + '"'
				if err is jsoncodec.UndefinedOutput {
					match input {
						map[string]json2.Any { received = 'Object' }
						[]json2.Any { received = 'Array' }
						else { received = diagnostics.issue_value(input) }
					}
				}

				return conversion_failure_input[json2.Any, string](input, 'stringify_json', 'JSON',
					'', received, text)
			}
			return types.Dataset[string]{
				value: output
			}
		}
	}
}

pub fn stringify_json_with_config_utf16(config jsoncodec.StringifyConfig, messages ...types.ErrorMessage) types.Transformation[json2.Any, []u16] {
	text := custom_message(messages, '')
	return types.Transformation[json2.Any, []u16]{
		type_name: 'stringify_json'
		run:       fn [config, text] (input json2.Any) types.Dataset[[]u16] {
			output := jsoncodec.stringify_utf16(input, config) or {
				return conversion_failure_input[json2.Any, []u16](input, 'stringify_json', 'JSON',
					'', if err is jsoncodec.UndefinedOutput {
					diagnostics.issue_value(input)
				} else {
					'"' + err.msg() + '"'
				}, text)
			}
			return types.Dataset[[]u16]{
				value: output
			}
		}
	}
}
