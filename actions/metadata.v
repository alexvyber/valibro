module actions

import valibro.types
import x.json2

fn native_annotation[T](name string, annotations types.Annotations) types.Action[T] {
	return types.Action[T]{
		kind:        .metadata
		type_name:   name
		annotations: annotations
		run:         fn [T](input T) types.Dataset[T] {
			return types.Dataset[T]{
				value: input
			}
		}
	}
}

pub fn title[T](text string) types.Action[T] {
	return native_annotation[T]('title', types.Annotations{ title: text })
}

pub fn description[T](text string) types.Action[T] {
	return native_annotation[T]('description', types.Annotations{ description: text })
}

pub fn metadata[T](entries map[string]json2.Any) types.Action[T] {
	return native_annotation[T]('metadata', types.Annotations{ metadata: entries.clone() })
}

pub fn examples[T](values []T) types.Action[T] {
	items := values.clone()
	return types.Action[T]{
		kind:            .metadata
		type_name:       'examples'
		native_examples: types.Examples[T]{
			present: true
			values:  items
		}
		run:             fn [T](input T) types.Dataset[T] {
			return types.Dataset[T]{
				value: input
			}
		}
	}
}

// Native V strings already have immutable contents.
pub fn message[T](action types.Action[T], text types.ErrorMessage) types.Action[T] {
	wrapped := types.contextual_action[T](action.type_name, action.kind, fn [action, text] [T](dataset types.Dataset[T], config types.Config) types.Dataset[T] {
		result := types.apply_action[T](action, dataset, config)
		mut issues := []types.Issue{cap: result.issues.len}
		for i, issue in result.issues {
			if i < dataset.issues.len {
				issues << issue
				continue
			}
			issues << types.Issue{
				...issue
				message:        types.resolve_message(text, issue)
				custom_message: true
			}
		}
		return types.Dataset[T]{
			...result
			issues: issues
		}
	})
	return types.Action[T]{
		...wrapped
		annotations:     action.annotations
		native_examples: action.native_examples
	}
}
