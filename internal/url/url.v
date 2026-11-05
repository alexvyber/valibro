module url

import encoding.utf8
import net
import net.urllib
import valibro.internal.formats

// Validate an absolute URI without browser-style repair or host normalization.
pub fn valid_url(input string) bool {
	if input == '' || !utf8.validate_str(input) { return false }
	for i, b in input.bytes() {
		if b <= 32 || b == 127 || b == `\\` { return false }
		if b == `%` && (i + 2 >= input.len || !is_hex(input[i + 1]) || !is_hex(input[i + 2])) {
			return false
		}
	}
	parsed := urllib.parse(input) or { return false }
	if parsed.scheme == '' { return false }
	scheme := parsed.scheme.to_lower()
	authority := input[parsed.scheme.len + 1..].starts_with('//')
	if scheme in ['http', 'https', 'ftp', 'ws', 'wss'] && (!authority || parsed.host == '') {
		return false
	}
	if scheme == 'file' && (!authority || !parsed.path.starts_with('/')) { return false }
	if parsed.host != '' {
		host := parsed.hostname()
		if host == '' || host.contains('%') || host.bytes().any(it >= 128) { return false }
		if parsed.host.starts_with('[') {
			net.canonical_ipv6(host) or { return false }
		} else {
			if host.contains(':') { return false }
			final_label := host.split('.').last()
			if final_label != '' && final_label.bytes().all(it >= `0` && it <= `9`) {
				parts := host.split('.')
				if parts.len != 4 { return false }
				for part in parts {
					if part == '' || part.len > 3 || !part.bytes().all(it >= `0` && it <= `9`)
						|| (part.len > 1 && part[0] == `0`) || part.int() > 255 {
						return false
					}
				}
			} else if !formats.valid_hostname(host, true) {
				return false
			}
		}
		if parsed.host.ends_with(':') { return false }
		port := parsed.port()
		if port != '' {
			if !port.bytes().all(it >= `0` && it <= `9`) { return false }
			significant := port.trim_left('0')
			if significant.len > 5 || significant.int() > 65535 { return false }
		}
	}
	if authority { return parsed.host != '' || (scheme == 'file' && parsed.path.starts_with('/')) }
	return parsed.opaque != '' || parsed.path != ''
}

fn is_hex(value u8) bool {
	return (value >= `0` && value <= `9`) || (value >= `a` && value <= `f`)
		|| (value >= `A` && value <= `F`)
}
