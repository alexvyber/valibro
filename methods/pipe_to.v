module methods

import valibro.types

// pipe_to composes a type-changing transformation without erasing its output type.
pub fn pipe_to[I, O, N](schema types.Schema[I, O], action types.Transformation[O, N]) types.Schema[I, N] {
	return types.Schema[I, N]{
		type_name:                schema.type_name
		expects:                  schema.expects
		message:                  schema.message
		default_value:            schema.default_value
		default_provider:         schema.default_provider
		default_context_provider: schema.default_context_provider
		annotations:              schema.annotations
		run:                      fn [schema, action] [I, O, N](input I, config types.Config) types.Dataset[N] {
			dataset := types.run[I, O](schema, input, config)
			if exception := dataset.exception { return types.Dataset[N]{
					typed:     false
					exception: exception
				} }
			if !dataset.typed || dataset.issues.len > 0 {
				mut value := N{}
				$if O is N {
					$if N is $array { value = dataset.value.clone() } $else { value = dataset.value }
				}
				return types.Dataset[N]{
					raw_value: dataset.raw_value or { types.value_of[O](dataset.value) }
					value:     value
					typed:     false
					issues:    dataset.issues
				}
			}
			return types.run_transformation[O, N](action, dataset.value, config)
		}
	}
}
