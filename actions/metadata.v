module actions

import valibro.types
import x.json2

pub fn title(text string) types.Action[string] {
	return annotation_action('title', types.Annotations{ title: text })
}

pub fn description(text string) types.Action[string] {
	return annotation_action('description', types.Annotations{ description: text })
}

pub fn examples(values []string) types.Action[string] {
	return annotation_action('examples', types.Annotations{ examples: values.clone() })
}

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

pub fn title_for[T](text string) types.Action[T] {
	return native_annotation[T]('title', types.Annotations{ title: text })
}

pub fn description_for[T](text string) types.Action[T] {
	return native_annotation[T]('description', types.Annotations{ description: text })
}

pub fn metadata_for[T](entries map[string]json2.Any) types.Action[T] {
	return native_annotation[T]('metadata', types.Annotations{ metadata: entries.clone() })
}

pub fn readonly_for[T]() types.Action[T] {
	return types.Action[T]{
		kind:      .transformation
		type_name: 'readonly'
		run:       fn [T](input T) types.Dataset[T] {
			return types.Dataset[T]{
				value: input
			}
		}
	}
}

pub fn brand_for[T, B]() types.Transformation[T, types.Branded[T, B]] {
	return types.Transformation[T, types.Branded[T, B]]{
		type_name: 'brand'
		run:       fn [T, B](input T) types.Dataset[types.Branded[T, B]] {
			return types.Dataset[types.Branded[T, B]]{
				value: types.Branded[T, B]{
					value: input
				}
			}
		}
	}
}

pub fn flavor_for[T, B]() types.Transformation[T, types.Flavored[T, B]] {
	return types.Transformation[T, types.Flavored[T, B]]{
		type_name: 'flavor'
		run:       fn [T, B](input T) types.Dataset[types.Flavored[T, B]] {
			return types.Dataset[types.Flavored[T, B]]{
				value: types.Flavored[T, B]{
					value: input
				}
			}
		}
	}
}

pub fn examples_for[T](values []T) types.Action[T] {
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

pub fn brand[B]() types.Transformation[string, types.Branded[string, B]] {
	return types.Transformation[string, types.Branded[string, B]]{
		type_name: 'brand'
		run:       fn [B](input string) types.Dataset[types.Branded[string, B]] {
			return types.Dataset[types.Branded[string, B]]{
				value: types.Branded[string, B]{
					value: input
				}
			}
		}
	}
}

pub fn flavor[B]() types.Transformation[string, types.Flavored[string, B]] {
	return types.Transformation[string, types.Flavored[string, B]]{
		type_name: 'flavor'
		run:       fn [B](input string) types.Dataset[types.Flavored[string, B]] {
			return types.Dataset[types.Flavored[string, B]]{
				value: types.Flavored[string, B]{
					value: input
				}
			}
		}
	}
}

// Native V strings already have immutable contents.
pub fn readonly() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'readonly'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: input
			}
		}
	}
}

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
