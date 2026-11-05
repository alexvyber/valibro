module actions

import valibro.jsoncodec
import valibro.types
import x.json2

pub fn parse_json(config jsoncodec.ParseConfig) types.Transformation[string, json2.Any] {
	return types.Transformation[string, json2.Any]{
		type_name: 'parse_json'
		run:       fn [config] (input string) types.Dataset[json2.Any] {
			output := jsoncodec.decode(input, config) or {
				return conversion_failure_input[string, json2.Any](input, 'parse_json', 'JSON', '',
					err.msg(), types.DefaultMessage{})
			}
			return types.Dataset[json2.Any]{
				value: output
			}
		}
	}
}
