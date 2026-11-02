module methods

import valibro.types

// pipe_to composes a type-changing transformation without erasing its output type.
pub fn pipe_to[I, O, N](schema types.Schema[I, O], action types.Transformation[O, N]) types.Schema[I, N] {
	return types.Schema[I, N]{
		type_name:   schema.type_name
		annotations: schema.annotations
		run:         fn [schema, action] [I, O, N](input I, config types.Config) types.Dataset[N] {
			dataset := schema.run(input, config)
			if !dataset.typed || dataset.issues.len > 0 { return types.Dataset[N]{
					typed:  false
					issues: dataset.issues
				} }
			return action.run(dataset.value)
		}
	}
}
