module diagnostics

import valibro.internal.number as numbers
import valibro.types

pub fn prepend_path(issues []types.Issue, key types.PathSegment, kinds ...string) []types.Issue {
	mut result := []types.Issue{cap: issues.len}
	for issue in issues {
		mut path := [key]
		kind := if kinds.len > 0 {
			kinds[0]
		} else {
			match key {
				int { 'array' }
				string { 'object' }
			}
		}
		mut path_types := [kind]
		raw_key := if kind == 'set' {
			types.value_of(types.Null{})
		} else {
			match key {
				int { types.value_of(key) }
				string { types.value_of(key) }
			}
		}
		mut raw_keys := [raw_key]
		for i, part in issue.path {
			raw_keys << if i < issue.path_keys.len {
				issue.path_keys[i]
			} else {
				match part {
					int { types.value_of(part) }
					string { types.value_of(part) }
				}
			}
			path_types << if i < issue.path_types.len {
				issue.path_types[i]
			} else {
				match part {
					int { 'array' }
					string { 'object' }
				}
			}
		}
		path << issue.path
		result << types.Issue{
			...issue
			path:         path
			path_types:   path_types
			path_keys:    raw_keys
			path_present: true
		}
	}
	return result
}

pub fn mark_dot_unavailable(issues []types.Issue) []types.Issue {
	return issues.map(types.Issue{ ...it, dot_path_unavailable: true, path_present: true })
}

pub fn prepend_map_path[T](issues []types.Issue, key T) []types.Issue {
	mut result := []types.Issue{}
	$if T is string {
		result = prepend_path(issues, key, 'map')
	} $else $if T is int {
		result = prepend_path(issues, key, 'map')
	} $else $if T is f32 || T is f64 {
		result = prepend_path(issues, numbers.native_number_string(f64(key)), 'map')
	} $else $if T is i8 || T is i16 || T is i32 || T is i64 || T is u8 || T is u16 || T is u32
		|| T is u64 || T is isize || T is usize {
		result = prepend_path(issues, key.str(), 'map')
	} $else {
		result = mark_dot_unavailable(prepend_path(issues, issue_value(key), 'map'))
	}
	mut output := []types.Issue{}
	for issue in result {
		mut keys := issue.path_keys.clone()
		keys[0] = types.value_of[T](key)
		output << types.Issue{
			...issue
			path_keys: keys
		}
	}
	return output
}

pub fn path_value(key types.PathSegment) types.NativeValue {
	return match key {
		int { types.value_of(key) }
		string { types.value_of(key) }
	}
}
