module schemas

import valibro.internal.diagnostics
import valibro.types

pub fn map_schema[K, L, I, O](key types.Schema[K, L], value types.Schema[I, O]) types.Schema[map[K]I, map[L]O] {
	return types.Schema[map[K]I, map[L]O]{
		type_name: 'map'
		expects:   'Map'
		run:       fn [key, value] [K, L, I, O](input map[K]I, config types.Config) types.Dataset[map[L]O] {
			mut output := map[L]O{}
			mut issues := []types.Issue{}
			mut raw_entries := []types.RawEntry{}
			mut has_raw := false
			mut typed := true
			for k, v in input {
				kr := types.run[K, L](key, k, config)
				if exception := kr.exception { return types.Dataset[map[L]O]{
						typed:     false
						exception: exception
					} }
				issues << diagnostics.prepend_map_path[K](kr.issues, k)
				typed = typed && kr.typed
				if config.abort_early && issues.len > 0 {
					typed = false
					break
				}
				vr := types.run[I, O](value, v, config)
				if exception := vr.exception { return types.Dataset[map[L]O]{
						typed:     false
						exception: exception
					} }
				issues << diagnostics.prepend_map_path[K](vr.issues, k)
				typed = typed && vr.typed
				if config.abort_early && issues.len > 0 {
					typed = false
					break
				}
				output[kr.value] = vr.value
				raw_key := kr.raw_value or { types.value_of[L](kr.value) }
				raw_item := vr.raw_value or { types.value_of[O](vr.value) }
				if kr.raw_value != none || vr.raw_value != none { has_raw = true }
				types.raw_entry_set(mut raw_entries, raw_key, raw_item)
			}
			mut raw_value := ?types.NativeValue(none)
			if has_raw { raw_value = types.value_of(types.RawMap{ entries: raw_entries }) }
			return types.Dataset[map[L]O]{
				raw_value: raw_value
				typed:     typed
				value:     output
				issues:    issues
			}
		}
	}
}
