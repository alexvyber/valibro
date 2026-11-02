module actions

import valibro.types

pub fn title(text string) types.Action[string] {
	return annotation_action('title', types.Annotations{ title: text })
}
