module valibro

import valibro.actions
import valibro.types
import math.big
import time
import x.json2

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

pub fn parse_json(messages ...types.ErrorMessage) types.Transformation[string, json2.Any] {
	return actions.parse_json(...messages)
}

pub fn stringify_json() types.Action[string] {
	return actions.stringify_json()
}

pub fn stringify_json_value[T]() types.Transformation[T, string] {
	return actions.stringify_json_value[T]()
}
