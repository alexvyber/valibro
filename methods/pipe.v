module methods

import valibro.types

// pipe copies its actions, preserving the original schema and action list.
// Validations may collect issues. A transformation never runs after an issue.
pub fn pipe[I, O](schema types.Schema[I, O], actions ...types.Action[O]) types.Schema[I, O] {
	return pipe_from_actions[I, O](schema, actions)
}

// pipe_from_actions composes an explicit list of actions.
pub fn pipe_from_actions[I, O](schema types.Schema[I, O], actions []types.Action[O]) types.Schema[I, O] {
	items := actions.clone()
	mut annotations := schema.annotations
	mut native_examples := types.Examples[O]{
		present: schema.native_examples.present
		values:  schema.native_examples.values.clone()
	}
	for action in items {
		annotations = merge_annotations(annotations, action.annotations)
		if action.native_examples.present { native_examples = types.Examples[O]{
				present: true
				values:  action.native_examples.values.clone()
			} }
	}
	return types.Schema[I, O]{
		...schema
		type_name:       schema.type_name
		annotations:     annotations
		native_examples: native_examples
		run:             fn [schema, items] [I, O](input I, config types.Config) types.Dataset[O] {
			mut dataset := types.run[I, O](schema, input, config)
			if dataset.exception != none { return dataset }
			for action in items {
				if action.kind == .metadata { continue
				 }
				if dataset.issues.len > 0 && action.kind == .transformation {
					dataset = types.Dataset[O]{
						...dataset
						typed: false
					}
					break
				}
				if dataset.issues.len > 0 && (config.abort_early || config.abort_pipe_early) { continue
				 }
				dataset = types.apply_action[O](action, dataset, config)
				if dataset.exception != none { return dataset }
			}
			return dataset
		}
	}
}
