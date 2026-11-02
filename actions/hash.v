module actions

import valibro.types

pub fn hash(algorithms []types.HashType, messages ...types.ErrorMessage) types.Action[string] {
	assert algorithms.len > 0, 'hash requires at least one algorithm'
	mut patterns := []string{}
	for algorithm in algorithms {
		size := match algorithm {
			.md4, .md5, .ripemd128, .tiger128 { 32 }
			.sha1, .ripemd160, .tiger160 { 40 }
			.sha256 { 64 }
			.sha384 { 96 }
			.sha512 { 128 }
			.tiger192 { 48 }
			.crc32, .crc32b, .adler32 { 8 }
		}

		patterns << '^[a-fA-F0-9]{${size}}\$'
	}
	return string_validation('hash', patterns.join('|'), messages)
}
