module actions

import valibro.types
import x.json2

pub fn metadata(entries map[string]json2.Any) types.Action[string] {
	return annotation_action('metadata', types.Annotations{ metadata: entries.clone() })
}

fn annotation_action(name string, annotations types.Annotations) types.Action[string] {
	return types.Action[string]{
		kind:        .metadata
		type_name:   name
		annotations: annotations
		run:         fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: input
			}
		}
	}
}
