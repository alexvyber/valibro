module main

import math.big
import time
import valibro as v

fn main() {
	age := v.pipe(v.number(), v.finite(), v.integer(), v.min_value(0.0), v.max_value(130.0))
	println(v.parse(age, 42.0) or { panic(err) })
	assert !v.safe_parse(age, 1.5).success

	count := v.pipe(v.number_of[int](), v.min_value(0), v.multiple_of(2))
	println(v.parse(count, 42) or { panic(err) })

	enabled := v.pipe(v.boolean(), v.value(true, 'Must be enabled'))
	assert v.parse(enabled, true) or { panic(err) }

	huge := big.integer_from_string('123456789012345678901234567890') or { panic(err) }
	balance := v.pipe(v.bigint(), v.min_value(big.integer_from_int(0)))
	println(v.parse(balance, huge) or { panic(err) })

	birthday := v.pipe(v.date(), v.min_value(time.new(time.Time{ year: 1900, month: 1, day: 1 })))
	println(v.parse(birthday, time.new(time.Time{ year: 2000, month: 2, day: 29 })) or {
		panic(err)
	})

	// Validation actions also compose after a string conversion.
	quantity := v.pipe(v.pipe_to(v.string(), v.to_number()), v.safe_integer(), v.min_value(1.0))
	println(v.parse(quantity, '12') or { panic(err) })
}
