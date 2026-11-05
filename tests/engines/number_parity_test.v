module valibro_test

import valibro.internal.number as impl_number
import valibro.tests.support
import math
import os
import x.json2

pub struct NumberOracle {
pub mut:
	input   string
	success bool
	bits    string
	text    string
}

fn test_number_string_conversion_rounding_overflow_and_subnormal_boundaries() {
	rows := json2.decode[[]NumberOracle](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/engines/numbers.json')) or { panic(err) }) or { panic(err) }
	mut failures := 0
	for row in rows {
		value := impl_number.number_from_string(row.input) or {
			if row.success {
				if failures < 8 { eprintln('Unexpected number error ${row.input}') }
				failures++
			}
			continue
		}
		if !row.success || math.f64_bits(value).str() != row.bits
			|| support.reference_number_string(value) != row.text {
			if failures < 8 {
				eprintln('Number mismatch ${row.input}: got ${value} (${math.f64_bits(value)}), expected bits ${row.bits}')
			}
			failures++
		}
	}
	assert failures == 0, '${failures} of ${rows.len} conversions differ'
}
