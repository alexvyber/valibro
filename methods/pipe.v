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
	for action in items {
		annotations = merge_annotations(annotations, action.annotations)
	}
	return types.Schema[I, O]{
		type_name:   schema.type_name
		annotations: annotations
		run:         fn [schema, items] [I, O](input I, config types.Config) types.Dataset[O] {
			mut dataset := schema.run(input, config)
			for action in items {
				if action.kind == .metadata { continue
				 }
				if !dataset.typed { break
				 }
				if dataset.issues.len > 0 && (config.abort_early || action.kind == .transformation) {
					break
				}
				next := action.run(dataset.value)
				mut issues := dataset.issues.clone()
				issues << next.issues
				dataset = types.Dataset[O]{
					typed:  next.typed
					value:  next.value
					issues: issues
				}
			}
			return dataset
		}
	}
}
