module valibro_test

import valibro as v
import valibro.utils

fn test_stdlib_regex_compilation_and_strict_end_anchor() {
	for pattern in [r'\p{Letter}', r'\z', r'(a)\1', r'(?=a)', '['] {
		utils.compile_pattern(pattern) or { continue }
		assert false, 'Unsupported regex was accepted: ${pattern}'
	}
	schema := v.pipe(v.string(), v.regex(r'^[a-z]+$'))
	assert v.safe_parse(schema, 'abc').success
	assert !v.safe_parse(schema, 'abc\n').success
	assert !v.safe_parse(schema, 'abc\u0000').success
	// Compiled schema use does not share a previous call's match state.
	assert !v.safe_parse(schema, '123').success
	assert v.safe_parse(schema, 'abc').success
}
