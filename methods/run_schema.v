module methods

import valibro.types

// Enforce the extension contract at the parse boundary, even if a custom runner
// reports a fatal failure without supplying its own issue.
fn run_schema[I, O](schema types.Schema[I, O], input I, config types.Config) types.Dataset[O] {
	dataset := schema.run(input, config)
	if !dataset.typed && dataset.issues.len == 0 {
		return types.Dataset[O]{
			...dataset
			issues: [
				types.Issue{
					code:     schema.type_name
					message:  'Schema did not produce a typed output'
					expected: 'typed output'
				},
			]
		}
	}
	return dataset
}
