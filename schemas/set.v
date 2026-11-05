module schemas

import valibro.internal.diagnostics
import valibro.types

pub fn set[I, O](item types.Schema[I, O]) types.Schema[types.Set[I], types.Set[O]] {
	return set_runner(item, default_set_equal[O], true)
}

pub type SetEquality[T] = fn (T, T) bool

pub fn set_with[I, O](item types.Schema[I, O], equal fn (O, O) bool) types.Schema[types.Set[I], types.Set[O]] {
	return set_runner(item, equal, false)
}

fn set_runner[I, O](item types.Schema[I, O], equal fn (O, O) bool, native_equality bool) types.Schema[types.Set[I], types.Set[O]] {
	return types.Schema[types.Set[I], types.Set[O]]{
		type_name: 'set'
		expects:   'Set'
		run:       fn [item, equal, native_equality] [I, O](input types.Set[I], config types.Config) types.Dataset[types.Set[O]] {
			return run_set[I, O](item, equal, native_equality, input, config)
		}
	}
}

fn run_set[I, O](item types.Schema[I, O], equal fn (O, O) bool, native_equality bool, input types.Set[I], config types.Config) types.Dataset[types.Set[O]] {
	mut values := []O{}
	mut issues := []types.Issue{}
	mut raw_items := []types.NativeValue{}
	mut has_raw := false
	mut typed := true
	for i, value in input.values {
		result := types.run[I, O](item, value, config)
		if exception := result.exception { return types.Dataset[types.Set[O]]{
				typed:     false
				exception: exception
			} }
		issues << diagnostics.mark_dot_unavailable(diagnostics.prepend_path(result.issues, i, 'set'))
		typed = typed && result.typed
		if config.abort_early && issues.len > 0 {
			typed = false
			break
		}
		values << result.value
		if raw := result.raw_value {
			has_raw = true
			raw_items << raw
		} else {
			raw_items << types.value_of[O](result.value)
		}
	}
	mut raw_value := ?types.NativeValue(none)
	if has_raw {
		if native_equality {
			raw_value = types.value_of(types.raw_set(raw_items))
		} else {
			raw_value = types.value_of(types.raw_set_with[O](raw_items, equal))
		}
	}
	mut output := types.Set[O]{}
	if native_equality {
		output = types.new_set[O](values)
	} else {
		output = types.new_set_with[O](values, equal)
	}

	return types.Dataset[types.Set[O]]{
		raw_value: raw_value
		typed:     typed
		value:     output
		issues:    issues
	}
}

fn default_set_equal[T](left T, right T) bool {
	return types.native_set_equal[T](left, right)
}
