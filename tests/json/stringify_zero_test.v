module valibro_test

import valibro.jsoncodec
import x.json2

fn test_binary64_stringify_normalizes_negative_zero_like_json_stringify() ! {
	assert jsoncodec.stringify(json2.Any(f64(-0.0)), binary64_numbers: true)! == '0'
	assert jsoncodec.stringify(json2.Any([json2.Any(f64(-0.0)), json2.Any(f64(0.0))]),
		binary64_numbers: true
	)! == '[0,0]'
}

fn test_binary64_stringify_uses_ecmascript_notation_thresholds() ! {
	assert jsoncodec.stringify(json2.Any([json2.Any(9007199254740992.0), json2.Any(0.0000001),
		json2.Any(0.000001), json2.Any(1e20), json2.Any(1e21)]), binary64_numbers: true)! == '[9007199254740992,1e-7,0.000001,100000000000000000000,1e+21]'
}
