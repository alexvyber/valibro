module json

import valibro.types
import x.json2

@[params]
pub struct FieldConfig {
pub:
	default_value ?json2.Any
}

// Accept a missing object field; explicit null is validated by the wrapped schema.
pub fn optional(schema Schema, config FieldConfig) Schema {
	return Schema{
		type_name:     'optional'
		expects:       schema.expects
		wrapped:       [schema]
		optional:      true
		default_value: config.default_value
		run:           schema.run
	}
}

// Accept explicit JSON null; missing-field policy is configured with optional.
pub fn nullable(schema Schema) Schema {
	return Schema{
		type_name: 'nullable'
		expects:   '(' + schema.expects + ' | null)'
		wrapped:   [schema]
		run:       fn [schema] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			if input is json2.Null { return types.Dataset[json2.Any]{
					value: input
				} }
			return run_json(schema, input, config)
		}
	}
}

pub fn fallback(schema Schema, value json2.Any) Schema {
	return Schema{
		...schema
		shape_rebuilder:  none
		fallback_value:   value
		fallback_wrapped: [schema]
		run:              fn [schema, value] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			result := run_json(schema, input, config)
			if result.exception != none || (result.typed && result.issues.len == 0) { return result }
			return types.Dataset[json2.Any]{
				value: value
			}
		}
	}
}

fn require_field(schema Schema, message types.ErrorMessage) Schema {
	return Schema{
		...schema
		optional: false
		message:  message
	}
}
