module actions

import valibro.types

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn base64(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('base64', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn decimal(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('decimal', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn digits(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('digits', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn hexadecimal(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('hexadecimal', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn hex_color(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('hex_color', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn octal(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('octal', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn slug(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('slug', messages)
}

pub fn hash(algorithms []types.HashType, messages ...types.ErrorMessage) types.Action[string] {
	assert algorithms.len > 0, 'hash requires at least one algorithm'
	mut patterns := []string{}
	for algorithm in algorithms {
		width := match algorithm {
			.md4, .md5, .ripemd128, .tiger128 { 32 }
			.sha1, .ripemd160, .tiger160 { 40 }
			.sha256 { 64 }
			.sha384 { 96 }
			.sha512 { 128 }
			.tiger192 { 48 }
			.crc32, .crc32b, .adler32 { 8 }
		}

		patterns << '^[a-fA-F0-9]{${width}}\$'
	}
	return string_validation('hash', patterns.join('|'), messages)
}
