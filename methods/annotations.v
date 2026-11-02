module methods

import valibro.types

fn merge_annotations(a types.Annotations, b types.Annotations) types.Annotations {
	mut entries := a.metadata.clone()
	for key, value in b.metadata {
		entries[key] = value
	}
	return types.Annotations{
		title:       if b.title != none { b.title } else { a.title }
		description: if b.description != none { b.description } else { a.description }
		examples:    if b.examples != none { b.examples } else { a.examples }
		metadata:    entries
	}
}
