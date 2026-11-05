module valibro

import valibro.actions
import valibro.methods
import valibro.schemas
import valibro.storages
import valibro.types

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

pub fn is_valid[I, O](schema types.Schema[I, O], input I) bool {
	return methods.is_valid[I, O](schema, input)
}

pub fn assert_valid[I, O](schema types.Schema[I, O], input I) ! {
	methods.assert_valid[I, O](schema, input)!
}

pub fn parser[I, O](schema types.Schema[I, O]) fn (I) !O {
	return methods.parser[I, O](schema)
}

pub fn safe_parser[I, O](schema types.Schema[I, O]) fn (I) types.SafeParseResult[O] {
	return methods.safe_parser[I, O](schema)
}

pub fn config[I, O](schema types.Schema[I, O], settings types.Config) types.Schema[I, O] {
	return methods.config[I, O](schema, settings)
}

pub fn forward[T](action types.Action[T], path []types.PathSegment) types.Action[T] {
	return methods.forward[T](action, path)
}

pub fn get_dot_path(issue types.Issue) string {
	return methods.get_dot_path(issue)
}

pub fn flatten(issues []types.Issue) methods.FlatErrors {
	return methods.flatten(issues)
}

pub fn summarize(issues []types.Issue) string {
	return methods.summarize(issues)
}

pub fn get_global_message(context types.Context, languages ...string) ?types.ErrorMessage {
	return storages.get_global_message(context, ...languages)
}

pub fn set_global_message(mut context types.Context, message types.ErrorMessage, languages ...string) {
	storages.set_global_message(mut context, message, ...languages)
}

pub fn delete_global_message(mut context types.Context, languages ...string) {
	storages.delete_global_message(mut context, ...languages)
}

pub fn get_schema_message(context types.Context, languages ...string) ?types.ErrorMessage {
	return storages.get_schema_message(context, ...languages)
}

pub fn set_schema_message(mut context types.Context, message types.ErrorMessage, languages ...string) {
	storages.set_schema_message(mut context, message, ...languages)
}

pub fn delete_schema_message(mut context types.Context, languages ...string) {
	storages.delete_schema_message(mut context, ...languages)
}

pub fn get_specific_message(context types.Context, kind string, languages ...string) ?types.ErrorMessage {
	return storages.get_specific_message(context, kind, ...languages)
}

pub fn set_specific_message(mut context types.Context, kind string, message types.ErrorMessage, languages ...string) {
	storages.set_specific_message(mut context, kind, message, ...languages)
}

pub fn delete_specific_message(mut context types.Context, kind string, languages ...string) {
	storages.delete_specific_message(mut context, kind, ...languages)
}

pub fn get_global_config(context types.Context) types.Config {
	return storages.get_global_config(context)
}

pub fn set_global_config(mut context types.Context, config types.Config) {
	storages.set_global_config(mut context, config)
}

pub fn delete_global_config(mut context types.Context) {
	storages.delete_global_config(mut context)
}

pub fn safe_parse_async[I, O](schema types.Schema[I, O], input I) chan types.SafeParseResult[O] {
	return methods.safe_parse_async[I, O](schema, input)
}

pub fn safe_parse_async_with_config[I, O](schema types.Schema[I, O], input I, config types.Config) chan types.SafeParseResult[O] {
	return methods.safe_parse_async_with_config[I, O](schema, input, config)
}

pub fn function_schema[I, O]() types.Schema[types.Function[I, O], types.Function[I, O]] {
	return schemas.function_schema[I, O]()
}

pub fn args[I, O, R](schema types.Schema[I, O]) types.Transformation[types.Function[O, R], types.FallibleFunction[I, R]] {
	return actions.args[I, O, R](schema)
}

pub fn returns[I, R, S](schema types.Schema[R, S]) types.Transformation[types.Function[I, R], types.FallibleFunction[I, S]] {
	return actions.returns[I, R, S](schema)
}

pub fn cache[I, O](schema types.Schema[I, O], key fn (I) string, capacity int) types.Schema[I, O] {
	return methods.cache[I, O](schema, key, capacity)
}

pub fn returns_checked[I, R, S](schema types.Schema[R, S]) types.Transformation[types.FallibleFunction[I, R], types.FallibleFunction[I, S]] {
	return actions.returns_checked[I, R, S](schema)
}

pub fn parser_async[I, O](schema types.Schema[I, O]) fn (I) types.Future[O] {
	return methods.parser_async[I, O](schema)
}

pub fn safe_parser_async[I, O](schema types.Schema[I, O]) fn (I) chan types.SafeParseResult[O] {
	return methods.safe_parser_async[I, O](schema)
}

pub fn safe_parse_checked[I, O](schema types.Schema[I, O], input I, configs ...types.Config) !types.SafeParseResult[O] {
	return methods.safe_parse_checked[I, O](schema, input, ...configs)
}

pub fn cache_with_config[I, O](schema types.Schema[I, O], key fn (I) string, config methods.CacheConfig) types.Schema[I, O] {
	return methods.cache_with_config[I, O](schema, key, config)
}

pub fn cached[I, O](schema types.Schema[I, O], key fn (I) string, config methods.CacheConfig) methods.CachedSchema[I, O] {
	return methods.cached[I, O](schema, key, config)
}

pub fn promise[T]() types.Schema[types.Future[T], types.Future[T]] {
	return schemas.promise[T]()
}

pub fn await_future[T]() types.Transformation[types.Future[T], T] {
	return actions.await_future[T]()
}

pub fn parse_async[I, O](schema types.Schema[I, O], input I) types.Future[O] {
	return types.new_future[O](methods.safe_parse_async[I, O](schema, input))
}

pub fn is_vali_error(err IError) bool {
	return methods.is_vali_error(err)
}

pub fn schema_is_of_type[I, O](schema types.Schema[I, O], name string) bool {
	return methods.schema_is_of_type(schema, name)
}

pub fn action_is_of_type[T](action types.Action[T], name string) bool {
	return methods.action_is_of_type(action, name)
}

pub fn action_is_of_kind[T](action types.Action[T], kind types.ActionKind) bool {
	return methods.action_is_of_kind(action, kind)
}

pub fn is_of_kind[T](item T, kind string) bool {
	return item.kind.str() == kind
}

pub fn is_of_type[T](item T, name string) bool {
	return item.type_name == name
}

pub fn pipe_to[I, O, N](schema types.Schema[I, O], action types.Transformation[O, N]) types.Schema[I, N] {
	return methods.pipe_to[I, O, N](schema, action)
}
