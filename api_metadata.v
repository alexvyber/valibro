module valibro

import valibro.actions
import valibro.types
import x.json2

pub fn get_title[I, O](schema types.Schema[I, O]) ?string {
	return schema.annotations.title
}

pub fn get_description[I, O](schema types.Schema[I, O]) ?string {
	return schema.annotations.description
}

pub fn get_metadata[I, O](schema types.Schema[I, O]) map[string]json2.Any {
	return schema.annotations.metadata.clone()
}

pub fn title[T](text string) types.Action[T] {
	return actions.title[T](text)
}

pub fn description[T](text string) types.Action[T] {
	return actions.description[T](text)
}

pub fn metadata[T](entries map[string]json2.Any) types.Action[T] {
	return actions.metadata[T](entries)
}

pub fn examples[T](values []T) types.Action[T] {
	return actions.examples[T](values)
}

pub fn get_examples[I, O](schema types.Schema[I, O]) ?[]O {
	if !schema.native_examples.present { return none }
	return schema.native_examples.values.clone()
}
