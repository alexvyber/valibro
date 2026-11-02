module main

import valibro as v

struct EmailTag {}

fn main() {
	email := v.pipe(v.string(), v.trim(), v.to_lower_case(), v.email(), v.max_length(254),
		v.title('Contact email'))
	address := v.parse(email, '  Alex@Example.com  ') or { panic(err) }
	println(address)

	password := v.pipe(v.string(), v.min_code_points(8), v.regex(r'[A-Z]'), v.regex(r'[0-9]'))
	assert v.safe_parse(password, 'Password123🙂').success

	number := v.pipe_to(v.string(), v.to_number())
	println(v.parse(number, '0xff') or { panic(err) })
	boolean := v.pipe_to(v.string(), v.parse_boolean())
	println(v.parse(boolean, 'YES') or { panic(err) })

	branded := v.pipe_to(email, v.brand[EmailTag]())
	value := v.parse(branded, 'alex@example.com') or { panic(err) }
	println(value.value)
}
