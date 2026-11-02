module valibro

import valibro.actions
import valibro.methods
import valibro.types

pub fn trim_start() types.Action[string] {
	return actions.trim_start()
}

pub fn trim_end() types.Action[string] {
	return actions.trim_end()
}

pub fn to_upper_case() types.Action[string] {
	return actions.to_upper_case()
}

pub fn to_camel_case() types.Action[string] {
	return actions.to_camel_case()
}

pub fn to_pascal_case() types.Action[string] {
	return actions.to_pascal_case()
}

pub fn to_kebab_case() types.Action[string] {
	return actions.to_kebab_case()
}

pub fn to_snake_case() types.Action[string] {
	return actions.to_snake_case()
}

pub fn to_string() types.Action[string] {
	return actions.to_string()
}

pub fn to_min_value(requirement string) types.Action[string] {
	return actions.to_min_value(requirement)
}

pub fn to_max_value(requirement string) types.Action[string] {
	return actions.to_max_value(requirement)
}

pub type ParseBooleanConfig = types.ParseBooleanConfig

pub fn pipe_to[I, O, N](schema types.Schema[I, O], action types.Transformation[O, N]) types.Schema[I, N] {
	return methods.pipe_to[I, O, N](schema, action)
}

pub fn transform[T](operation fn (T) T) types.Action[T] {
	return actions.transform[T](operation)
}

pub fn transform_to[I, O](operation fn (I) O) types.Transformation[I, O] {
	return actions.transform_to[I, O](operation)
}

pub fn raw_transform[T](operation fn (T) types.Dataset[T]) types.Action[T] {
	return actions.raw_transform[T](operation)
}

pub fn raw_transform_to[I, O](operation fn (I) types.Dataset[O]) types.Transformation[I, O] {
	return actions.raw_transform_to[I, O](operation)
}

pub fn raw_check[T](operation fn (T) []types.Issue) types.Action[T] {
	return actions.raw_check[T](operation)
}

pub fn guard[T](predicate fn (T) bool, messages ...types.ErrorMessage) types.Action[T] {
	return actions.guard[T](predicate, ...messages)
}
