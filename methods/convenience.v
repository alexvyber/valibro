module methods

import valibro.internal.diagnostics
import valibro.types

pub fn is_valid[I, O](schema types.Schema[I, O], input I) bool {
	return safe_parse(schema, input).success
}

pub fn assert_valid[I, O](schema types.Schema[I, O], input I) ! {
	parse(schema, input)!
}

pub fn parser[I, O](schema types.Schema[I, O]) fn (I) !O {
	return fn [schema] [I, O](input I) !O {
		return parse(schema, input)
	}
}

pub fn safe_parser[I, O](schema types.Schema[I, O]) fn (I) types.SafeParseResult[O] {
	return fn [schema] [I, O](input I) types.SafeParseResult[O] {
		return safe_parse(schema, input)
	}
}

pub fn config[I, O](schema types.Schema[I, O], settings types.Config) types.Schema[I, O] {
	return types.Schema[I, O]{
		...schema
		run: fn [schema, settings] [I, O](input I, ignored types.Config) types.Dataset[O] {
			return run_schema(schema, input, settings)
		}
	}
}

pub fn fallback[I, O](schema types.Schema[I, O], value O) types.Schema[I, O] {
	result := fallback_fn(schema, fn [value] [I, O](input I, issues []types.Issue) O {
		return value
	})
	return types.Schema[I, O]{
		...result
		fallback_value: value
	}
}

pub fn fallback_fn[I, O](schema types.Schema[I, O], getter fn (I, []types.Issue) O) types.Schema[I, O] {
	return types.Schema[I, O]{
		...schema
		fallback_value:    none
		fallback_provider: types.FallbackProvider[O]{}
		run:               fn [schema, getter] [I, O](input I, config types.Config) types.Dataset[O] {
			result := run_schema(schema, input, config)
			if result.exception != none { return result }
			if result.typed && result.issues.len == 0 { return result }
			return types.Dataset[O]{
				value: getter(input, result.issues)
			}
		}
	}
}

pub fn forward[T](action types.Action[T], path []types.PathSegment) types.Action[T] {
	keys := path.clone()
	wrapped := types.contextual_action[T](action.type_name, action.kind, fn [action, keys] [T](dataset types.Dataset[T], config types.Config) types.Dataset[T] {
		result := types.apply_action[T](action, dataset, config)
		mut issues := []types.Issue{cap: result.issues.len}
		for i, issue in result.issues {
			if i < dataset.issues.len {
				issues << issue
				continue
			}
			mut forwarded := issue.path.clone()
			forwarded << diagnostics.forward_keys[T](result.value, keys)
			mut path_types := issue.path_types.clone()
			for path_types.len < forwarded.len {
				path_types << 'unknown'
			}
			issues << types.Issue{
				...issue
				path_types:   path_types
				path_keys:    forwarded.map(diagnostics.path_value(it))
				path_present: issue.path_present || forwarded.len > 0
				path:         forwarded
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

// Context-aware counterpart of an upstream fallback factory callback.
pub fn fallback_with_context[I, O](schema types.Schema[I, O], getter fn (?types.Dataset[O], types.Config) O) types.Schema[I, O] {
	return types.Schema[I, O]{
		...schema
		fallback_value:    none
		fallback_provider: types.FallbackProvider[O]{
			available: true
			get:       getter
		}
		run:               fn [schema, getter] [I, O](input I, config types.Config) types.Dataset[O] {
			result := run_schema(schema, input, config)
			if result.exception != none || result.issues.len == 0 { return result }
			return types.Dataset[O]{
				value: getter(result, config)
			}
		}
	}
}
