module utils

import net.urllib

// Validate absolute hierarchical URLs with an ASCII scheme and host. Supported
// schemes are http, https, ws, wss, and ftp; this is not a WHATWG URL parser.
pub fn valid_url(input string) bool {
	if input == '' { return false }
	for r in input.runes() {
		if r <= 32 || r == 127 || js_space(r) || r == `\\` { return false }
	}
	mut i := 0
	for i < input.len {
		if input[i] == `%` {
			if i + 2 >= input.len || !ascii_hex(input[i + 1]) || !ascii_hex(input[i + 2]) {
				return false
			}
			i += 3
		} else {
			i++
		}
	}
	parsed := urllib.parse(input) or { return false }
	if parsed.scheme.to_lower() !in ['http', 'https', 'ws', 'wss', 'ftp'] { return false }
	if parsed.opaque != '' || parsed.host == '' { return false }
	// Require the explicit authority marker; urllib also accepts opaque URLs.
	colon := input.index(':') or { return false }
	if !input[colon + 1..].starts_with('//') { return false }
	hostport := parsed.host
	mut host := hostport
	mut port := ''
	if hostport.starts_with('[') {
		end := hostport.index(']') or { return false }
		host = hostport[1..end]
		if host.contains('%') || !matches(ipv6_regex, host) { return false }
		tail := hostport[end + 1..]
		if tail != '' {
			if !tail.starts_with(':') { return false }
			port = tail[1..]
			if port == '' { return false }
		}
	} else {
		if hostport.contains(':') {
			parts := hostport.split(':')
			if parts.len != 2 || parts[1] == '' { return false }
			host = parts[0]
			port = parts[1]
		}
		if !valid_hostname(host, true) { return false }
		// A dotted all-numeric host is an IPv4 address, not a DNS name.
		if host.contains('.') && host.bytes().all((it >= `0` && it <= `9`) || it == `.`) {
			if !matches(ipv4_regex, host) { return false }
		}
	}
	if port != '' {
		mut number := 0
		for b in port.bytes() {
			if b < `0` || b > `9` { return false }
			number = number * 10 + int(b - `0`)
			if number > 65535 { return false }
		}
	}
	return true
}
