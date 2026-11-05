module schemas

import valibro.internal.diagnostics
import valibro.types

// record validates and transforms both keys and values of a native string-keyed map.
pub fn record[I, O](key types.Schema[string, string], value types.Schema[I, O]) types.Schema[map[string]I, map[string]O] {
	return types.Schema[map[string]I, map[string]O]{
		type_name: 'record'
		expects:   'Object'
		run:       fn [key, value] [I, O](input map[string]I, config types.Config) types.Dataset[map[string]O] {
			mut output := map[string]O{}
			mut issues := []types.Issue{}
			mut raw_entries := []types.RawEntry{}
			mut has_raw := false
			mut typed := true
			for name in input.keys() {
				entry := input[name]
				k := types.run[string, string](key, name, config)
				if exception := k.exception { return types.Dataset[map[string]O]{
						typed:     false
						exception: exception
					} }
				issues << diagnostics.prepend_path(k.issues, name)
				typed = typed && k.typed
				if config.abort_early && issues.len > 0 {
					typed = false
					break
				}
				v := types.run[I, O](value, entry, config)
				if exception := v.exception { return types.Dataset[map[string]O]{
						typed:     false
						exception: exception
					} }
				issues << diagnostics.prepend_path(v.issues, name)
				typed = typed && v.typed
				if config.abort_early && issues.len > 0 {
					typed = false
					break
				}
				if k.typed {
					output[k.value] = v.value
					raw_item := v.raw_value or { types.value_of[O](v.value) }
					if v.raw_value != none { has_raw = true }
					types.raw_entry_set(mut raw_entries, types.value_of(k.value), raw_item)
				}
			}
			mut raw_value := ?types.NativeValue(none)
			if has_raw { raw_value = types.value_of(types.RawObject{ entries: raw_entries }) }
			return types.Dataset[map[string]O]{
				raw_value: raw_value
				typed:     typed
				value:     output
				issues:    issues
			}
		}
	}
}
