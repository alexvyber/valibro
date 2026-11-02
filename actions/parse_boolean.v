module actions

import valibro.types

pub fn parse_boolean(messages ...types.ErrorMessage) types.Transformation[string, bool] {
	return parse_boolean_with_config(types.ParseBooleanConfig{}, ...messages)
}

pub fn parse_boolean_with_config(config types.ParseBooleanConfig, messages ...types.ErrorMessage) types.Transformation[string, bool] {
	truthy := config.truthy.map(it.to_lower())
	falsy := config.falsy.map(it.to_lower())
	text := custom_message(messages, 'Invalid boolean')
	return types.Transformation[string, bool]{
		type_name: 'parse_boolean'
		run:       fn [truthy, falsy, text] (input string) types.Dataset[bool] {
			normalized := input.to_lower()
			if normalized in truthy { return types.Dataset[bool]{
					value: true
				} }
			if normalized in falsy { return types.Dataset[bool]{
					value: false
				} }
			return types.Dataset[bool]{
				typed:  false
				issues: [types.new_issue('parse_boolean', text, '', input)]
			}
		}
	}
}
