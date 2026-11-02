module actions

import valibro.types

pub fn examples(values []string) types.Action[string] {
	return annotation_action('examples', types.Annotations{ examples: values.clone() })
}
