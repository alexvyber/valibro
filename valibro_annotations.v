module valibro

import valibro.actions
import valibro.types
import x.json2

pub fn title(text string) types.Action[string] {
	return actions.title(text)
}

pub fn description(text string) types.Action[string] {
	return actions.description(text)
}

pub fn examples(values []string) types.Action[string] {
	return actions.examples(values)
}

pub fn metadata(entries map[string]json2.Any) types.Action[string] {
	return actions.metadata(entries)
}

pub fn get_title[I, O](schema types.Schema[I, O]) ?string {
	return schema.annotations.title
}

pub fn get_description[I, O](schema types.Schema[I, O]) ?string {
	return schema.annotations.description
}

pub fn get_examples[I, O](schema types.Schema[I, O]) ?[]string {
	return schema.annotations.examples
}

pub fn get_metadata[I, O](schema types.Schema[I, O]) map[string]json2.Any {
	return schema.annotations.metadata.clone()
}

pub fn readonly() types.Action[string] {
	return actions.readonly()
}

pub fn brand[B]() types.Transformation[string, types.Branded[string, B]] {
	return actions.brand[B]()
}

pub fn flavor[B]() types.Transformation[string, types.Flavored[string, B]] {
	return actions.flavor[B]()
}
