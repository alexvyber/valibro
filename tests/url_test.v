module valibro_test

import valibro as v

fn test_supported_absolute_urls() {
	schema := v.pipe(v.string(), v.url())
	for input in [
		'https://example.com',
		'HTTP://example.com/path?x=1#fragment',
		'https://user:password@example.com:443/a%20b',
		'ftp://example.com/download',
		'ws://localhost:0',
		'wss://example.com:65535',
		'http://127.0.0.1:8080/',
		'http://example.com:000080/',
		'https://[2001:db8::1]:443/',
		'https://[::ffff:192.0.2.1]/',
		'https://xn--bcher-kva.example/путь?q=ёж',
	] {
		assert v.safe_parse(schema, input).success, input
	}
}

fn test_invalid_urls_and_explicit_scope_boundaries() {
	schema := v.pipe(v.string(), v.url('Unsupported or malformed URL'))
	for input in [
		'',
		'example.com',
		'/relative',
		'//example.com',
		'https:example.com',
		'http:/example.com',
		'http:///example.com',
		'http://',
		'http://:80',
		'http://user@',
		'http://example.com:',
		'http://example.com:-1',
		'http://example.com:65536',
		'http://example.com:99999999999999',
		'http://example.com:foo',
		'http://example.com:12:34',
		'http://[invalid]/',
		'http://[::1',
		'http://[::1]junk',
		'http://[fe80::1%25en0]/',
		'http://256.0.0.1/',
		'http://01.2.3.4/',
		'http://a..example/',
		'http://-bad.example/',
		'http://bad_.example/',
		'http://example.com./',
		'http://example.com/a b',
		'http://example.com/a\tb',
		' http://example.com',
		'http://example.com\n',
		'http://example.com/\u00a0',
		'http://example.com\\evil',
		'http://example.com/%',
		'http://example.com/?x=%GG',
		'http://bücher.example/',
		'mailto:alex@example.com',
		'file:///tmp/example',
		'data:text/plain,hello',
		'abc:1234',
		'javascript:alert(1)',
	] {
		result := v.safe_parse(schema, input)
		assert !result.success, input
		assert result.output == none
		assert result.issues[0].code == 'url'
		assert result.issues[0].message == 'Unsupported or malformed URL'
	}
}
