module text

import regex.pcre
import encoding.utf8

// Compile once per factory. Compiled programs are immutable; the stdlib creates
// per-call matching state, so schemas can be reused without sharing match state.
pub fn compile_pattern(pattern string) !pcre.Regex {
	if !utf8.validate_str(pattern) { return error('Regex pattern must be valid UTF-8') }
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

// Native convenience flags map directly to V's inline modifiers.
pub fn compile_pattern_with_flags(pattern string, flags string) !pcre.Regex {
	mut seen := ''
	for flag in flags.bytes() {
		if flag !in [`i`, `m`, `s`] {
			return error('Unsupported native regex flag: ' + flag.ascii_str())
		}
		if seen.contains(flag.ascii_str()) {
			return error('Duplicate native regex flag: ' + flag.ascii_str())
		}
		seen += flag.ascii_str()
	}
	if flags == '' { return compile_pattern(pattern) }
	return compile_pattern('(?' + flags + ')' + pattern)
}
