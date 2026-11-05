module schemas

import valibro.internal.diagnostics
import valibro.types

pub fn array_schema[I, O](item types.Schema[I, O]) types.Schema[[]I, []O] {
	return types.Schema[[]I, []O]{
		type_name: 'array'
		expects:   'Array'
		run:       fn [item] [I, O](input []I, config types.Config) types.Dataset[[]O] {
			mut output := []O{cap: input.len}
			mut issues := []types.Issue{}
			mut raw_items := []types.NativeValue{}
			mut has_raw := false
			mut typed := true
			for index, value in input {
				result := types.run[I, O](item, value, config)
				if exception := result.exception { return types.Dataset[[]O]{
						typed:     false
						exception: exception
					} }
				typed = typed && result.typed
				issues << diagnostics.prepend_path(result.issues, index)
				if !result.typed && result.issues.len == 0 {
					issues << types.schema_issue('array', types.DefaultMessage{
						text: 'Item did not produce a typed output'
					}, 'typed output', '')
				}
				if config.abort_early && issues.len > 0 {
					typed = false
					break
				}
				output << result.value
				if raw := result.raw_value {
					has_raw = true
					raw_items << raw
				} else {
					raw_items << types.value_of[O](result.value)
				}
			}
			mut raw_value := ?types.NativeValue(none)
			if has_raw { raw_value = types.value_of(types.RawArray{ items: raw_items }) }
			return types.Dataset[[]O]{
				raw_value: raw_value
				typed:     typed
				value:     output
				issues:    issues
			}
		}
	}
}
