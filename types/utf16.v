module types

// Explicit UTF-16 encoding/accessors for interoperability; ordinary diagnostics use whole characters.
pub fn utf16_units(input string) []u16 {
	mut output := []u16{}
	for r in input.runes() {
		if r > 0xffff {
			value := u32(r) - 0x10000
			output << u16(0xd800 + (value >> 10))
			output << u16(0xdc00 + (value & 1023))
		} else {
			output << u16(r)
		}
	}
	return output
}

// Valid pairs become UTF-8; unpaired surrogates have an escaped display spelling.
pub fn utf16_display(input []u16) string {
	mut output := ''
	for i := 0; i < input.len; i++ {
		unit := input[i]
		if unit >= 0xd800 && unit <= 0xdbff && i + 1 < input.len && input[i + 1] >= 0xdc00
			&& input[i + 1] <= 0xdfff {
			output += rune(0x10000 + (u32(unit) - 0xd800) * 1024 + u32(input[i + 1]) - 0xdc00).str()
			i++
		} else if unit >= 0xd800 && unit <= 0xdfff {
			output += '\\u' + unit.hex_full()
		} else {
			output += rune(unit).str()
		}
	}
	return output
}

pub fn (issue Issue) received_units() []u16 {
	return utf16_units(issue.received)
}

pub fn (issue Issue) message_units() []u16 {
	return utf16_units(issue.message)
}
