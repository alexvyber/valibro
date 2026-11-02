module valibro

import valibro.actions
import valibro.types

pub fn empty(messages ...types.ErrorMessage) types.Action[string] {
	return actions.empty(...messages)
}

pub fn non_empty(messages ...types.ErrorMessage) types.Action[string] {
	return actions.non_empty(...messages)
}

pub fn credit_card(messages ...types.ErrorMessage) types.Action[string] {
	return actions.credit_card(...messages)
}

pub fn imei(messages ...types.ErrorMessage) types.Action[string] {
	return actions.imei(...messages)
}

pub fn isbn(messages ...types.ErrorMessage) types.Action[string] {
	return actions.isbn(...messages)
}

pub fn includes(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.includes(requirement, ...messages)
}

pub fn excludes(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.excludes(requirement, ...messages)
}

pub fn value(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.value(requirement, ...messages)
}

pub fn not_value(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.not_value(requirement, ...messages)
}

pub fn values(requirements []string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.values(requirements, ...messages)
}

pub fn not_values(requirements []string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.not_values(requirements, ...messages)
}

pub fn min_value(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.min_value(requirement, ...messages)
}

pub fn max_value(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.max_value(requirement, ...messages)
}

pub fn gt_value(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.gt_value(requirement, ...messages)
}

pub fn lt_value(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.lt_value(requirement, ...messages)
}

pub type HashType = types.HashType

pub fn hash(algorithms []types.HashType, messages ...types.ErrorMessage) types.Action[string] {
	return actions.hash(algorithms, ...messages)
}

pub fn regex(pattern string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.regex(pattern, ...messages)
}

pub fn url(messages ...types.ErrorMessage) types.Action[string] {
	return actions.url(...messages)
}
