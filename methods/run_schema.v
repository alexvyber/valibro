module methods

import valibro.types

// Enforce the extension contract and resolve context messages at the parse boundary.
fn run_schema[I, O](schema types.Schema[I, O], input I, config types.Config) types.Dataset[O] {
	mut dataset := types.run[I, O](schema, input, config)
	if dataset.exception != none { return dataset }
	if !dataset.typed && dataset.issues.len == 0 {
		dataset = types.Dataset[O]{
			...dataset
			issues: [
				types.schema_issue(schema.type_name, types.DefaultMessage{
					text: 'Schema did not produce a typed output'
				}, 'typed output', ''),
			]
		}
	}
	return apply_messages(dataset, config)
}
