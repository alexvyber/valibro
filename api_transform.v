module valibro

import math.big
import time
import valibro.actions
import valibro.jsoncodec
import valibro.types
import valibro.unicode
import x.json2

pub fn trim() types.Action[string] {
	return actions.trim()
}

pub fn to_lower_case() types.Action[string] {
	return actions.to_lower_case()
}

pub fn to_number(messages ...types.ErrorMessage) types.Transformation[string, f64] {
	return actions.to_number(...messages)
}

pub fn to_bigint(messages ...types.ErrorMessage) types.Transformation[string, big.Integer] {
	return actions.to_bigint(...messages)
}

pub fn to_date(messages ...types.ErrorMessage) types.Transformation[string, time.Time] {
	return actions.to_date(...messages)
}

pub fn to_boolean() types.Transformation[string, bool] {
	return actions.to_boolean()
}

pub fn parse_boolean(messages ...types.ErrorMessage) types.Transformation[string, bool] {
	return actions.parse_boolean(...messages)
}

pub fn parse_boolean_with_config(config types.ParseBooleanConfig, messages ...types.ErrorMessage) types.Transformation[string, bool] {
	return actions.parse_boolean_with_config(config, ...messages)
}

pub fn raw_transform_with_context[T](operation fn (types.Dataset[T], types.Config) types.Dataset[T]) types.Action[T] {
	return actions.raw_transform_with_context[T](operation)
}

pub fn raw_transform_to_with_context[I, O](operation fn (types.Dataset[I], types.Config) types.Dataset[O]) types.Transformation[I, O] {
	return actions.raw_transform_to_with_context[I, O](operation)
}

pub fn to_number_from[T](messages ...types.ErrorMessage) types.Transformation[T, f64] {
	return actions.to_number_from[T](...messages)
}

pub fn to_bigint_from[T](messages ...types.ErrorMessage) types.Transformation[T, big.Integer] {
	return actions.to_bigint_from[T](...messages)
}

pub fn to_boolean_from[T](messages ...types.ErrorMessage) types.Transformation[T, bool] {
	return actions.to_boolean_from[T](...messages)
}

pub fn to_date_from[T](messages ...types.ErrorMessage) types.Transformation[T, time.Time] {
	return actions.to_date_from[T](...messages)
}

pub fn to_string_from[T](messages ...types.ErrorMessage) types.Transformation[T, string] {
	return actions.to_string_from[T](...messages)
}

pub fn parse_boolean_from[T](messages ...types.ErrorMessage) types.Transformation[T, bool] {
	return actions.parse_boolean_from[T](...messages)
}

pub fn parse_boolean_with_values[T](truthy []T, falsy []T, messages ...types.ErrorMessage) types.Transformation[T, bool] {
	return actions.parse_boolean_with_values[T](truthy, falsy, ...messages)
}

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

pub fn to_min_value[T](requirement T) types.Action[T] {
	return actions.to_min_value[T](requirement)
}

pub fn to_max_value[T](requirement T) types.Action[T] {
	return actions.to_max_value[T](requirement)
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

pub fn guard[T](predicate fn (T) bool, messages ...types.ErrorMessage) types.Action[T] {
	return actions.guard[T](predicate, ...messages)
}

pub fn normalize(forms ...unicode.NormalizeForm) types.Action[string] {
	return actions.normalize(...forms)
}

pub fn try_transform[I, O](operation fn (I) !O) types.Transformation[I, O] {
	return actions.try_transform(operation)
}

pub fn parse_json(config jsoncodec.ParseConfig) types.Transformation[string, json2.Any] {
	return actions.parse_json(config)
}

pub fn stringify_json_value[T](config jsoncodec.StringifyConfig) types.Transformation[T, string] {
	return actions.stringify_json_value[T](config)
}
