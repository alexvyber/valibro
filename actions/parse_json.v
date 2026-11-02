module actions

import valibro.types
import x.json2

pub fn parse_json(messages ...types.ErrorMessage) types.Transformation[string, json2.Any] {
	text := custom_message(messages, 'Invalid JSON')
	return types.Transformation[string, json2.Any]{
		type_name: 'parse_json'
		run:       fn [text] (input string) types.Dataset[json2.Any] {
			converted := json2.decode[json2.Any](input) or {
				return types.Dataset[json2.Any]{
					typed:  false
					issues: [types.new_issue('parse_json', text, '', input)]
				}
			}
			return types.Dataset[json2.Any]{
				value: converted
			}
		}
	}
}
