module main

import valibro as v

type Email = string

fn main() {
	email := v.pipe(v.string(), v.trim(), v.to_lower_case(), v.email(), v.max_length(254),
		v.title[string]('Contact email'))
	address := v.parse(email, '  Alex@Example.com  ') or { panic(err) }
	println(address)

	password := v.pipe(v.string(), v.min_code_points(8), v.regex(r'[A-Z]'), v.regex(r'[0-9]'))
	assert v.is_valid(password, 'Password123🙂')!

	number := v.pipe_to(v.string(), v.to_number())
	println(v.parse(number, '0xff') or { panic(err) })
	boolean := v.pipe_to(v.string(), v.parse_boolean())
	println(v.parse(boolean, 'YES') or { panic(err) })

	domain_email := v.pipe_to(email, v.transform_to[string, Email](fn (value string) Email {
		return Email(value)
	}))
	value := v.parse(domain_email, 'alex@example.com') or { panic(err) }
	println(value)
}
