module utils

import regex.pcre

// Compile once per factory. Compiled programs are immutable; the stdlib creates
// per-call matching state, so schemas can be reused without sharing match state.
pub fn compile_pattern(pattern string) !pcre.Regex {
	// The stdlib treats some unknown escapes literally; reject those that could
	// otherwise silently turn unsupported syntax into literal text.
	mut i := 0
	mut in_class := false
	for i < pattern.len {
		if pattern[i] == `\\` {
			if i + 1 >= pattern.len { return error('Trailing regex escape') }
			next := pattern[i + 1]
			if next in [`p`, `P`, `z`, `Z`, `u`, `k`] || (next >= `1` && next <= `9`) {
				return error('Unsupported regex escape')
			}
			i += 2
		} else {
			if pattern[i] == `[` { in_class = true }
			if pattern[i] == `]` { in_class = false }
			if !in_class && pattern[i..].starts_with('(?') {
				tail := pattern[i + 2..]
				if !tail.starts_with(':') && !tail.starts_with('P<') {
					mut flags := 0
					for flags < tail.len && tail[flags] in [`i`, `m`, `s`] {
						flags++
					}
					if flags == 0 || flags >= tail.len || tail[flags] !in [`:`, `)`] {
						return error('Unsupported regex group')
					}
				}
			}
			i++
		}
	}
	return pcre.compile(pattern)
}

pub fn matches(pattern string, input string) bool {
	compiled := compile_pattern(pattern) or { return false }
	if _ := compiled.find(input) { return true }
	return false
}
