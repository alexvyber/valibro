module types

pub struct MapEntry[K, V] {
pub:
	key   K
	value V
}

pub struct EntryMap[K, V] {
pub:
	entries []MapEntry[K, V]
}

// Explicit comparison supports arbitrary native keys and reference identities.
pub fn entry_map[K, V](entries []MapEntry[K, V], equal fn (K, K) bool) EntryMap[K, V] {
	mut output := []MapEntry[K, V]{}
	for entry in entries {
		mut found := false
		for index, existing in output {
			if equal(existing.key, entry.key) {
				output[index] = MapEntry[K, V]{
					key:   existing.key
					value: entry.value
				}
				found = true
				break
			}
		}
		if !found { output << entry }
	}
	return EntryMap[K, V]{
		entries: output
	}
}

pub fn (value EntryMap[K, V]) count() int {
	return value.entries.len
}

pub fn new_set_with[T](values []T, equal fn (T, T) bool) Set[T] {
	mut output := []T{}
	for value in values {
		mut found := false
		for existing in output {
			if equal(value, existing) {
				found = true
				break
			}
		}
		if !found { output << value }
	}
	return Set[T]{
		values: output
	}
}
