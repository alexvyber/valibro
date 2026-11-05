module main

fn format_summary(name string) string {
	formats := {
		'base64':               'Require standard padded Base64 alphabet/shape, including the empty encoding; this validates text and does not decode it.'
		'bic':                  'Validate an 8- or 11-character BIC/SWIFT identifier shape with the supported country-code policy, without contacting a bank.'
		'cuid2':                'Require a lowercase letter followed by lowercase letters/digits. This shape check does not require one fixed CUID2 length or guarantee uniqueness.'
		'decimal':              'Require decimal digit text with optional sign and fractional prefix, without exponent notation; this does not convert the string to a number.'
		'digits':               'Require a nonempty digit-only string; a sign, decimal point, or exponent fails.'
		'domain':               'Validate domain labels with the package’s native hostname policy; this does not resolve DNS or verify that a domain is registered.'
		'email':                'Check the package’s practical email-address pattern with a dotted domain; it does not verify that the mailbox exists or accepts mail.'
		'rfc_email':            'Apply the broader RFC-style email syntax pattern, allowing local-part punctuation and domains without a required public suffix; no delivery check is performed.'
		'hexadecimal':          'Require hexadecimal digits with an optional lowercase 0x or 0h prefix; this preserves text instead of parsing an integer.'
		'hex_color':            'Require a # prefix followed by 3, 4, 6, or 8 hexadecimal digits, covering RGB and RGBA text forms.'
		'ipv4':                 'Require a dotted IPv4 address with four decimal octets in range; this does not connect to or resolve the address.'
		'ipv6':                 'Check expanded/compressed IPv6 text and supported embedded-IPv4/zone forms with the native pattern.'
		'ip':                   'Accept a supported IPv4 or IPv6 address representation, without network I/O.'
		'iso_date':             'Require YYYY-MM-DD text with month/day component ranges. This is a shape check, not Gregorian leap-day validation; use to_date/date for calendar validation.'
		'iso_date_time':        'Require a four-digit date plus T or space and HH:MM. This checks component ranges, not calendar validity or timezone conversion.'
		'iso_date_time_second': 'Require a four-digit date plus T or space and HH:MM:SS, without a fractional or timezone suffix.'
		'iso_timestamp':        'Require a four-digit date/time through seconds, optional 1–9 fractional digits, and Z or a supported numeric offset; this validates shape, not calendar validity.'
		'iso_time':             'Require a 24-hour HH:MM string with hour/minute component ranges.'
		'iso_time_second':      'Require 24-hour HH:MM:SS text; fractions and timezone suffixes are not accepted here.'
		'iso_week':             'Require YYYY-W01 through YYYY-W53 syntax, without verifying whether that particular year has week 53.'
		'jws_compact':          'Validate the three dot-separated Base64url-shaped compact JWS segments. It does not decode claims or verify a signature.'
		'isrc':                 'Validate compact or hyphen-separated country/registrant/year/designation ISRC syntax, without checking a recording registry.'
		'ksuid':                'Require exactly 27 ASCII alphanumeric characters. This is a representation check, not timestamp decoding or uniqueness verification.'
		'mac':                  'Accept supported 48- or 64-bit MAC-address text forms, without inspecting a network device.'
		'mac48':                'Require six hexadecimal byte pairs with consistent colon/hyphen separators, or the supported dotted 48-bit representation.'
		'mac64':                'Validate supported 64-bit hexadecimal MAC text forms, including byte-separated and grouped representations.'
		'nanoid':               'Require nonempty ASCII letters, digits, underscore, or hyphen. It does not enforce Nano ID’s customary generated length.'
		'octal':                'Require octal digits, optionally prefixed by lowercase 0o; the result stays a string.'
		'slug':                 'Require lowercase alphanumeric segments separated by one hyphen or underscore; leading, trailing, or repeated separators fail.'
		'ulid':                 'Require a 26-character ULID representation with a valid leading range and Crockford-style alphabet, without generating an ID.'
		'uuid':                 'Accept supported UUID versions 1–8 and the nil/max forms with their required hyphens; matching is case-insensitive.'
		'imei':                 'Check the supported 15-digit IMEI representation, including its Luhn checksum; this does not verify device registration.'
		'isbn':                 'Check a supported ISBN-10/ISBN-13 representation and its checksum, without verifying a book registry.'
		'credit_card':          'Check supported card-number shape/prefix rules and Luhn checksum. This is not payment authorization or proof that an account exists.'
	}
	return formats[name] or { '' }
}

fn format_example(name string) string {
	samples := {
		'base64':               'Zg=='
		'bic':                  'DEUTDEFF'
		'cuid2':                'o2dyrckf0vbqhftbcx8ex7r8'
		'decimal':              '12.5'
		'digits':               '123'
		'domain':               'example.com'
		'email':                'alex@example.com'
		'hexadecimal':          '0xff'
		'hex_color':            '#abc'
		'ipv4':                 '192.0.2.1'
		'ipv6':                 '2001:db8::1'
		'ip':                   '192.0.2.1'
		'iso_date':             '2024-02-29'
		'iso_date_time':        '2024-02-29T12:30'
		'iso_date_time_second': '2024-02-29T12:30:45'
		'iso_time':             '12:30'
		'iso_time_second':      '12:30:45'
		'iso_timestamp':        '2024-02-29T12:30:45.123Z'
		'iso_week':             '2024-W01'
		'jws_compact':          'ab.cd.ef'
		'isrc':                 'DEU671703268'
		'ksuid':                '0ujsswThIGTUYm2K8FjOOfXtY1K'
		'mac':                  'b6:05:20:67:f9:58'
		'mac48':                'b6:05:20:67:f9:58'
		'mac64':                '00:25:96:FF:FE:12:34:56'
		'nanoid':               'aB_123-xyz'
		'octal':                '0o123'
		'rfc_email':            'alex@example.com'
		'slug':                 'hello-world'
		'ulid':                 '01ARZ3NDEKTSV4RRFFQ69G5FAV'
		'uuid':                 'a6021db4-0b07-11ef-9262-0242ac120002'
		'imei':                 '861812069402168'
		'isbn':                 '4873118735'
		'credit_card':          '378282246310005'
		'emoji':                '🙂'
		'url':                  'https://example.com/path'
	}
	good := samples[name] or { return '' }
	bad := if name in ['nanoid', 'slug'] {
		'é'
	} else if name == 'cuid2' {
		'123'
	} else {
		'x'
	}
	return "import valibro as v\n\nschema := v.pipe(v.string(), v.${name}())\nassert v.is_valid(schema, '${good}')!\nassert !v.is_valid(schema, '${bad}')!\n"
}
