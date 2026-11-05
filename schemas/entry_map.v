module schemas

import valibro.internal.diagnostics
import valibro.types

pub fn entry_map[K, L, I, O](key types.Schema[K, L], value types.Schema[I, O], equal fn (L, L) bool) types.Schema[types.EntryMap[K, I], types.EntryMap[L, O]] {
	return types.Schema[types.EntryMap[K, I], types.EntryMap[L, O]]{
		type_name: 'map'
		expects:   'Map'
		run:       fn [key, value, equal] [K, L, I, O](input types.EntryMap[K, I], config types.Config) types.Dataset[types.EntryMap[L, O]] {
			mut entries := []types.MapEntry[L, O]{}
			mut issues := []types.Issue{}
			mut typed := true
			mut raw_entries := []types.RawEntry{}
			mut has_raw := false
			for entry in input.entries {
				checked_key := types.run(key, entry.key, config)
				if checked_key.exception != none { return types.Dataset[types.EntryMap[L, O]]{
						typed:     false
						exception: checked_key.exception
					} }
				issues << diagnostics.prepend_map_path[K](checked_key.issues, entry.key)
				if config.abort_early && issues.len > 0 {
					typed = false
					break
				}
				checked_value := types.run(value, entry.value, config)
				if checked_value.exception != none { return types.Dataset[types.EntryMap[L, O]]{
						typed:     false
						exception: checked_value.exception
					} }
				issues << diagnostics.prepend_map_path[K](checked_value.issues, entry.key)
				if config.abort_early && issues.len > 0 {
					typed = false
					break
				}
				typed = typed && checked_key.typed && checked_value.typed
				entries << types.MapEntry[L, O]{
					key:   checked_key.value
					value: checked_value.value
				}
				raw_key := checked_key.raw_value or { types.value_of(checked_key.value) }
				raw_item := checked_value.raw_value or { types.value_of(checked_value.value) }
				if checked_key.raw_value != none || checked_value.raw_value != none {
					has_raw = true
				}
				types.raw_entry_set_with[L](mut raw_entries, raw_key, raw_item, equal)
			}
			mut raw_value := ?types.NativeValue(none)
			if has_raw { raw_value = types.value_of(types.RawMap{ entries: raw_entries }) }
			return types.Dataset[types.EntryMap[L, O]]{
				typed:     typed
				value:     types.entry_map(entries, equal)
				issues:    issues
				raw_value: raw_value
			}
		}
	}
}
