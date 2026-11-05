module valibro_test

import valibro.tests.support
import x.json2
import valibro as v

pub struct FormatCase {
pub:
	action   string
	input    string
	valid    bool
	message  string
	received string
}

pub struct NativeFormatProfile {
pub:
	action       string
	input        string
	native_valid bool
	reason       string
}

fn test_string_formats_match_reference_and_explicit_native_profile() {
	mut cases := json2.decode[[]FormatCase]($embed_file('../fixtures/strings/string_formats.json').to_string()) or {
		panic(err)
	}
	cases << json2.decode[[]FormatCase]($embed_file('../fixtures/engines/formats_extended.json').to_string()) or {
		panic(err)
	}

	actions := [v.base64(), v.bic(), v.cuid2(), v.decimal(), v.digits(),
		v.domain(), v.email(), v.hexadecimal(), v.hex_color(),
		v.ipv4(), v.ipv6(), v.ip(), v.iso_date(), v.iso_date_time(),
		v.iso_date_time_second(), v.iso_time(), v.iso_time_second(),
		v.iso_timestamp(), v.iso_week(), v.jws_compact(), v.isrc(),
		v.ksuid(), v.mac(), v.mac48(), v.mac64(), v.nanoid(),
		v.octal(), v.rfc_email(), v.slug(), v.ulid(), v.uuid(),
		v.imei(), v.isbn(), v.credit_card()]
	profiles := json2.decode[[]NativeFormatProfile]($embed_file('../fixtures/strings/native_format_profile.json').to_string()) or {
		panic(err)
	}
	mut profile_cases := 0
	mut checked := 0
	for action in actions {
		schema := v.pipe(v.string(), action)
		for row in cases {
			if row.action != action.type_name { continue
			 }
			result := support.observe(schema, row.input)
			mut expected := row.valid
			for profile in profiles {
				if profile.action == row.action && profile.input == row.input {
					expected = profile.native_valid
					profile_cases++
				}
			}
			assert result.success == expected, '${row.action}: ${row.input} expected ${expected}'
			if !result.success {
				assert result.issues[0].code == row.action
				if row.message != '' {
					assert result.issues[0].message == row.message, '${row.action}: ${row.input}'
					assert result.issues[0].received == row.received
					assert result.issues[0].expected == ''
				}
			}
			checked++
		}
	}
	assert profile_cases == profiles.len
	assert checked == cases.len
}
