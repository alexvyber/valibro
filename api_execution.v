module valibro

import valibro.methods
import valibro.types

pub fn pipe[I, O](schema types.Schema[I, O], items ...types.Action[O]) types.Schema[I, O] {
	return methods.pipe_from_actions[I, O](schema, items)
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

pub fn cached[I, O](schema types.Schema[I, O], key fn (I) string, config methods.CacheConfig) methods.CachedSchema[I, O] {
	return methods.cached[I, O](schema, key, config)
}

pub fn pipe_to[I, O, N](schema types.Schema[I, O], action types.Transformation[O, N]) types.Schema[I, N] {
	return methods.pipe_to[I, O, N](schema, action)
}

pub fn parse[I, O](schema types.Schema[I, O], input I, config types.Config) !O {
	return methods.parse[I, O](schema, input, config)
}

pub fn inspect[I, O](schema types.Schema[I, O], input I, config types.Config) !types.Dataset[O] {
	return methods.inspect[I, O](schema, input, config)
}

pub fn is_valid[I, O](schema types.Schema[I, O], input I, config types.Config) !bool {
	return methods.is_valid[I, O](schema, input, config)
}

pub fn cache[I, O](schema types.Schema[I, O], key fn (I) string, config methods.CacheConfig) types.Schema[I, O] {
	return methods.cache[I, O](schema, key, config)
}
