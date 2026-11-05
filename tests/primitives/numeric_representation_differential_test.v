module valibro_test

import valibro.internal.coercion as impl_coercion
import math.big
import valibro.internal.comparison as impl_comparison
import valibro.tests.support
import os
import time
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

struct NumericRepPrimitive[T] {
	value T
}

pub fn (value NumericRepPrimitive[T]) to_number() !f64 {
	return impl_coercion.native_number[T](value.value)
}

pub fn (value NumericRepPrimitive[T]) to_bigint() !big.Integer {
	return impl_coercion.native_bigint[T](value.value)
}

pub fn (value NumericRepPrimitive[T]) to_date() !time.Time {
	return impl_coercion.native_date[T](value.value)
}

pub fn (value NumericRepPrimitive[T]) to_string() !string {
	return impl_coercion.native_string_checked[T](value.value)
}

fn numeric_rep_result[T](result types.SafeParseResult[T]) (bool, bool, string, []types.Issue) {
	if !result.success { return false, result.typed, '', result.issues }
	value := numeric_rep_unwrap[T](result.output)
	$if T is time.Time {
		return true, result.typed, value.unix_milli().str(), result.issues
	} $else $if T is json2.Any {
		return true, result.typed, support.reference_string[json2.Any](value), result.issues
	} $else {
		return true, result.typed, support.reference_string[T](value), result.issues
	}
}

fn numeric_rep_schema[T](action string, messages []types.ErrorMessage) types.Schema[T, T] {
	base := v.number_of[T]()
	match action {
		'number' { return v.number_of[T](...messages) }
		'finite' { return v.pipe(base, v.finite_of[T](...messages)) }
		'integer' { return v.pipe(base, v.integer_of[T](...messages)) }
		'safeInteger' { return v.pipe(base, v.safe_integer_of[T](...messages)) }
		'multipleOf' { return v.pipe(base, v.multiple_of(T(2), ...messages)) }
		'minValue' { return v.pipe(base, v.min_value(T(2), ...messages)) }
		'maxValue' { return v.pipe(base, v.max_value(T(2), ...messages)) }
		'gtValue' { return v.pipe(base, v.gt_value(T(2), ...messages)) }
		'ltValue' { return v.pipe(base, v.lt_value(T(2), ...messages)) }
		'value' { return v.pipe(base, v.value(T(2), ...messages)) }
		'toMinValue' { return v.pipe(base, v.to_min_value(T(2))) }
		'toMaxValue' { return v.pipe(base, v.to_max_value(T(2))) }
		'values' { return v.pipe(base, v.values([T(0), T(2)], ...messages)) }
		else { panic(action) }
	}
}

fn numeric_rep_conversion[T](action string, input T, messages []types.ErrorMessage) (bool, bool, string, []types.Issue) {
	base := v.unknown[T]()
	match action {
		'toNumber' {
			return numeric_rep_result(v.safe_parse(v.pipe_to(base, v.to_number_from[T](...messages)),
				input))
		}
		'toBigint' {
			return numeric_rep_result(v.safe_parse(v.pipe_to(base, v.to_bigint_from[T](...messages)),
				input))
		}
		'toDate' {
			return numeric_rep_result(v.safe_parse(v.pipe_to(base, v.to_date_from[T](...messages)),
				input))
		}
		'toString' {
			return numeric_rep_result(v.safe_parse(v.pipe_to(base, v.to_string_from[T](...messages)),
				input))
		}
		'parseBoolean' {
			return numeric_rep_result(v.safe_parse(v.pipe_to(base,
				v.parse_boolean_from[T](...messages)), input))
		}
		'stringifyJson' {
			return numeric_rep_result(v.safe_parse(v.pipe_to(base,
				v.stringify_json_value[T](...messages)), input))
		}
		'toBoolean' {
			return numeric_rep_result(v.safe_parse(v.pipe_to(base, v.to_boolean_from[T]()), input))
		}
		else {
			panic(action)
		}
	}
}

fn assert_numeric_rep(row map[string]json2.Any, success bool, typed bool, output string, issues []types.Issue) {
	assert success == (row['success'] or { panic('success') }).bool(), row.str()
	assert typed == (row['typed'] or { panic('typed') }).bool(), row.str()
	assert output == (row['output'] or { panic('output') }).str(), '${row}: ${output}'
	details := issues.map(json2.Any({
		'code':     json2.Any(it.code)
		'expected': json2.Any(it.expected)
		'received': json2.Any(it.received)
		'message':  json2.Any(it.message)
	}))
	assert j.equal(json2.Any(details), row['issues'] or { panic('issues') }), '${row}: ${details}'
}

fn numeric_rep_case[T](row map[string]json2.Any, input T) {
	boxed := numeric_rep_box[T](input)
	if family := row['family'] {
		if family.str() == 'wide_multiple' {
			divisor := T((row['divisor'] or { panic('divisor') }).str().i64())
			result := types.run_action(v.multiple_of(divisor), input)
			assert result.exception == none, row.str()
			assert (result.issues.len == 0) == (row['success'] or { panic('success') }).bool(), row.str()
		} else {
			comparison := json2.Any(boxed.f64())
			assert impl_comparison.value_equal(boxed, comparison), row.str()
			assert j.equal(boxed, comparison), row.str()
			assert types.new_set([boxed, comparison]).values.len == 1, row.str()
		}
		return
	}
	action := (row['action'] or { panic('action') }).str()
	if action == 'number' {
		adapted := j.safe_parse(j.from_schema(v.pipe_to(v.number(),
			v.transform_to[f64, T](numeric_rep_convert[T]))), json2.Any(f64(input)))
		assert adapted.success, row.str()
		assert j.equal(adapted.output or { panic('output') }, boxed), row.str()
	}
	messages := if (row['mode'] or { panic('mode') }).str() == 'factory' { [
			types.ErrorMessage('Factory message'),
		] } else { []types.ErrorMessage{} }
	if action in ['toNumber', 'toBigint', 'toBoolean', 'parseBoolean', 'toDate', 'toString',
		'stringifyJson'] {
		success, typed, output, issues := numeric_rep_conversion[T](action, input, messages)
		assert_numeric_rep(row, success, typed, output, issues)
		jsuccess, jtyped, joutput, jissues := numeric_rep_conversion[json2.Any](action, boxed,
			messages)
		assert_numeric_rep(row, jsuccess, jtyped, joutput, jissues)
		if action in ['toNumber', 'toBigint', 'toString', 'toDate'] {
			hsuccess, htyped, houtput, hissues := numeric_rep_conversion[NumericRepPrimitive[T]](action, NumericRepPrimitive[T]{
				value: input
			}, messages)
			assert_numeric_rep(row, hsuccess, htyped, houtput, hissues)
		}
	} else {
		success, typed, output, issues := numeric_rep_result(v.safe_parse(numeric_rep_schema[T](action,
			messages), input))
		assert_numeric_rep(row, success, typed, output, issues)
		result := j.safe_parse(j.from_schema(numeric_rep_schema[f64](action, messages)), boxed)
		jsuccess, jtyped, joutput, jissues := numeric_rep_result(result)
		assert_numeric_rep(row, jsuccess, jtyped, joutput, jissues)
	}
}

fn numeric_rep_box[T](input T) json2.Any {
	$if T is isize {
		return json2.Any(i64(input))
	} $else $if T is usize {
		return json2.Any(u64(input))
	} $else {
		return json2.Any(input)
	}
}

fn test_native_numeric_representations_match_valibot() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/primitives/numeric_representation_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		text := row['input']!.str()
		kind := row['kind']!.str()
		if sizeof(usize) == 4 {
			if kind == 'isize' && (text.i64() < -2147483648 || text.i64() > 2147483647) { continue
			 }
			if kind == 'usize' && text.u64() > 4294967295 { continue
			 }
		}
		match row['kind']!.str() {
			'i8' { numeric_rep_case[i8](row, i8(text.i64())) }
			'i16' { numeric_rep_case[i16](row, i16(text.i64())) }
			'i32' { numeric_rep_case[i32](row, i32(text.i64())) }
			'u8' { numeric_rep_case[u8](row, u8(text.u64())) }
			'u16' { numeric_rep_case[u16](row, u16(text.u64())) }
			'u32' { numeric_rep_case[u32](row, u32(text.u64())) }
			'isize' { numeric_rep_case[isize](row, isize(text.i64())) }
			'usize' { numeric_rep_case[usize](row, usize(text.u64())) }
			else { panic(row.str()) }
		}
	}
}

fn numeric_rep_unwrap[T](value ?T) T {
	return value or { panic('output') }
}

fn numeric_rep_convert[T](value f64) T {
	return T(value)
}
