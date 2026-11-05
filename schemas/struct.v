module schemas

import valibro.internal.diagnostics
import valibro.types

pub fn field[P, Q, I, O](name string, getter fn (P) I, setter fn (Q, O) Q, schema types.Schema[I, O]) types.Field[P, Q] {
	return types.Field[P, Q]{
		name: name
		run:  fn [name, getter, setter, schema] [P, Q, I, O](input P, output Q, config types.Config) types.Dataset[Q] {
			return run_field[P, Q, I, O](name, getter, setter, schema, input, output, config)
		}
	}
}

fn run_field[P, Q, I, O](name string, getter fn (P) I, setter fn (Q, O) Q, schema types.Schema[I, O], input P, output Q, config types.Config) types.Dataset[Q] {
	result := types.run[I, O](schema, getter(input), config)
	if exception := result.exception { return types.Dataset[Q]{
			typed:     false
			exception: exception
		} }
	mut value := output
	if result.typed { value = setter(output, result.value) }
	mut raw_value := ?types.NativeValue(none)
	if !result.typed || result.raw_value != none {
		field_value := result.raw_value or { types.value_of[O](result.value) }
		raw_value = types.value_of(types.RawStruct[Q]{
			value:  value
			fields: {
				name: field_value
			}
		})
	}
	return types.Dataset[Q]{
		raw_value: raw_value
		typed:     result.typed
		value:     value
		issues:    diagnostics.prepend_path(result.issues, name)
	}
}

pub fn object[T](fields ...types.Field[T, T]) types.Schema[T, T] {
	return object_from(fn [T](input T) T {
		return input
	}, fields)
}

pub fn object_from[I, O](initial fn (I) O, fields []types.Field[I, O]) types.Schema[I, O] {
	items := fields.clone()
	return types.Schema[I, O]{
		type_name: 'object'
		expects:   'Object'
		run:       fn [initial, items] [I, O](input I, config types.Config) types.Dataset[O] {
			return run_object_from[I, O](initial, items, input, config)
		}
	}
}

fn run_object_from[I, O](initial fn (I) O, items []types.Field[I, O], input I, config types.Config) types.Dataset[O] {
	mut output := initial(input)
	mut issues := []types.Issue{}
	mut raw_fields := map[string]types.NativeValue{}
	mut raw_keys := []string{}
	mut typed := true
	for field in items {
		result := invoke_field[I, O](field, input, output, config)
		if exception := result.exception { return types.Dataset[O]{
				typed:     false
				exception: exception
			} }
		output = result.value

		typed = typed && result.typed
		issues << result.issues
		if config.abort_early && issues.len > 0 {
			typed = false
			break
		}
		raw_keys << field.name
		if raw := result.raw_value {
			view := types.value_as[types.RawStruct[O]](raw) or {
				return types.Dataset[O]{
					typed:     false
					exception: err
				}
			}
			for name, value in view.fields {
				raw_fields[name] = value
			}
		}
	}
	mut raw_value := ?types.NativeValue(none)
	if raw_fields.len > 0 || issues.len > 0 { raw_value = types.value_of(types.RawStruct[O]{
			value:  output
			keys:   raw_keys
			fields: raw_fields
		}) }
	return types.Dataset[O]{
		raw_value: raw_value
		typed:     typed
		value:     output
		issues:    issues
	}
}

// Isolate the callback return type across nested field specializations in V 0.5.2.
fn invoke_field[I, O](field types.Field[I, O], input I, output O, config types.Config) types.Dataset[O] {
	return field.run(input, output, config)
}
