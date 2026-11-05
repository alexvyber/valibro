module diagnostics

import x.json2
import valibro.types

pub fn forward_keys[T](input T, keys []types.PathSegment) []types.PathSegment {
	$if T is json2.Any {
		mut current := input
		mut output := []types.PathSegment{}
		for key in keys {
			match current {
				map[string]json2.Any {
					if key is string {
						if next := current[key] {
							output << key
							current = next
							continue
						}
					}
				}
				[]json2.Any {
					if key is int {
						if key >= 0 && key < current.len {
							output << key
							current = current[key]
							continue
						}
					}
				}
				else {}
			}

			break
		}
		return output
	} $else {
		return keys.clone()
	}
}
