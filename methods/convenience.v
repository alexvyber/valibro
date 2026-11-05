module methods

import valibro.internal.diagnostics
import valibro.types

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
	}
}

pub fn fallback_fn[I, O](schema types.Schema[I, O], getter fn (I, []types.Issue) O) types.Schema[I, O] {
	return types.Schema[I, O]{
		...schema
		run: fn [schema, getter] [I, O](input I, config types.Config) types.Dataset[O] {
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
