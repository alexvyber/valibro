module valibro_test

import valibro.jsoncodec
import x.json2

fn test_binary64_stringify_normalizes_negative_zero_like_json_stringify() ! {
	assert jsoncodec.stringify(json2.Any(f64(-0.0)), binary64_numbers: true)! == '0'
	assert jsoncodec.stringify(json2.Any([json2.Any(f64(-0.0)), json2.Any(f64(0.0))]),
		binary64_numbers: true
	)! == '[0,0]'
}
