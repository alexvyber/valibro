module actions

import valibro.types

pub fn description(text string) types.Action[string] {
	return annotation_action('description', types.Annotations{ description: text })
}
