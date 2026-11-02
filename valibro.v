// Valibro provides composable, statically typed validation for V.
module valibro

import valibro.actions
import valibro.methods
import valibro.schemas
import valibro.types

pub type ErrorMessage = types.ErrorMessage

pub type Config = types.Config
pub type Issue = types.Issue
pub type PathSegment = types.PathSegment
pub type ValidationError = types.ValidationError
pub type ActionKind = types.ActionKind

pub fn string(messages ...types.ErrorMessage) types.Schema[string, string] {
	return schemas.string(...messages)
}

pub fn pipe[I, O](schema types.Schema[I, O], items ...types.Action[O]) types.Schema[I, O] {
	return methods.pipe_from_actions[I, O](schema, items)
}

pub fn safe_parse[I, O](schema types.Schema[I, O], input I) types.SafeParseResult[O] {
	return methods.safe_parse[I, O](schema, input)
}

pub fn safe_parse_with_config[I, O](schema types.Schema[I, O], input I, config types.Config) types.SafeParseResult[O] {
	return methods.safe_parse_with_config[I, O](schema, input, config)
}

pub fn parse[I, O](schema types.Schema[I, O], input I) !O {
	return methods.parse[I, O](schema, input)
}

pub fn parse_with_config[I, O](schema types.Schema[I, O], input I, config types.Config) !O {
	return methods.parse_with_config[I, O](schema, input, config)
}

pub fn trim() types.Action[string] {
	return actions.trim()
}

pub fn to_lower_case() types.Action[string] {
	return actions.to_lower_case()
}

pub fn min_length(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.min_length(requirement, ...messages)
}

pub fn max_length(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.max_length(requirement, ...messages)
}

pub fn starts_with(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.starts_with(requirement, ...messages)
}

pub fn ends_with(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.ends_with(requirement, ...messages)
}

pub fn check[T](predicate fn (T) bool, messages ...types.ErrorMessage) types.Action[T] {
	return actions.check[T](predicate, ...messages)
}

pub fn message[T](action types.Action[T], text types.ErrorMessage) types.Action[T] {
	return actions.message[T](action, text)
}

// message_fn adapts a callback using the public Issue alias to the shared contract.
pub fn message_fn(callback fn (Issue) string) types.ErrorMessage {
	handler := fn [callback] (issue types.Issue) string {
		return callback(Issue(issue))
	}
	return types.MessageFunction(handler)
}
