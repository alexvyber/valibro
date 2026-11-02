module valibro_test

import x.json2
import valibro as v

pub struct FormatCase {
pub:
	action string
	input  string
	valid  bool
}

fn test_upstream_string_format_cases() {
	cases := json2.decode[[]FormatCase]($embed_file('fixtures/string_formats.json').to_string()) or {
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
	mut checked := 0
	for action in actions {
		schema := v.pipe(v.string(), action)
		for row in cases {
			if row.action != action.type_name { continue
			 }
			result := v.safe_parse(schema, row.input)
			assert result.success == row.valid, '${row.action}: ${row.input} expected ${row.valid}'
			if !result.success { assert result.issues[0].code == row.action
			 }
			checked++
		}
	}
	assert checked == cases.len
}
