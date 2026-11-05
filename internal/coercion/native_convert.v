module coercion

import valibro.internal.date as dates
import valibro.internal.number as numbers
import math
import x.json2
import math.big
import time
import valibro.types

pub fn native_number[T](input T) !f64 {
	$if T is $array || T is $array_fixed {
		return types.TypeError{
			message: 'Collections require an explicit numeric conversion'
		}
	} $else $if T is types.NativeMaybe {
		return maybe_number[T](input)
	} $else $if T is types.NumberProvider {
		result := input.to_number()!
		if math.is_nan(result) { return error('NaN') }
		return result
	} $else $if T is types.InvalidDate {
		return error('NaN')
	} $else $if T is types.Symbol {
		return types.TypeError{
			message: 'Cannot convert a Symbol value to a number'
		}
	} $else $if T is json2.Any {
		return json_number(input)
	} $else $if T is types.Null {
		return types.TypeError{
			message: 'Null is not a number'
		}
	} $else $if T is types.Undefined {
		return error('Undefined is not a number')
	} $else $if T is string {
		return numbers.number_from_string(input)
	} $else $if T is bool {
		return if input { 1.0 } else { 0.0 }
	} $else $if T is i8 || T is i16 || T is int || T is i32 || T is i64 || T is u8 || T is u16
		|| T is u32 || T is u64 || T is isize || T is usize || T is f32 || T is f64 {
		value := f64(input)
		if math.is_nan(value) { return error('NaN') }
		return value
	} $else $if T is big.Integer {
		return numbers.number_from_string(input.str())
	} $else $if T is time.Time {
		valid := dates.validated_native_date(input) or { return error('NaN') }
		return f64(valid.unix_milli())
	} $else {
		$compile_error('to_number_from supports strings, booleans, native numbers, big integers, and dates')
	}
}

pub fn native_bigint[T](input T) !big.Integer {
	$if T is $array || T is $array_fixed {
		return types.TypeError{
			message: 'Collections require an explicit integer conversion'
		}
	} $else $if T is types.NativeMaybe {
		return maybe_bigint[T](input)
	} $else $if T is types.BigintProvider {
		return input.to_bigint()
	} $else $if T is time.Time {
		valid := dates.validated_native_date(input)!
		return native_bigint(valid.unix_milli())
	} $else $if T is types.Symbol || T is types.Null || T is types.Undefined
		|| T is types.InvalidDate {
		return types.TypeError{
			message: 'Cannot convert value to BigInt'
		}
	} $else $if T is json2.Any {
		return json_bigint(input)
	} $else $if T is string {
		return numbers.bigint_from_string(input)
	} $else $if T is bool {
		return big.integer_from_int(if input { 1 } else { 0 })
	} $else $if T is f32 || T is f64 {
		value := f64(input)
		if math.is_nan(value) || math.is_inf(value, 0) || math.trunc(value) != value {
			return error('Not an integer')
		}
		if value == 0 { return big.integer_from_int(0) }
		bits := math.f64_bits(value)
		exponent := int((bits >> 52) & 0x7ff) - 1023
		mantissa := (bits & u64(0x000fffffffffffff)) | u64(0x0010000000000000)
		base := big.integer_from_u64(mantissa)
		result := if exponent >= 52 {
			base.left_shift(u32(exponent - 52))
		} else {
			base.right_shift(u32(52 - exponent))
		}
		return if math.signbit(value) { result.neg() } else { result }
	} $else $if T is i8 || T is i16 || T is int || T is i32 || T is i64 || T is u8 || T is u16
		|| T is u32 || T is u64 || T is isize || T is usize {
		return big.integer_from_string(input.str())
	} $else $if T is big.Integer {
		return input
	} $else {
		$compile_error('to_bigint_from requires a string, boolean, native number, or big integer')
	}
}

pub fn native_boolean[T](input T) !bool {
	$if T is types.NativeMaybe {
		return maybe_boolean[T](input)
	} $else $if T is json2.Any {
		return json_boolean(input)
	} $else $if T is types.Null || T is types.Undefined {
		return false
	} $else $if T is types.BooleanProvider {
		return input.to_boolean()
	} $else $if T is string {
		return input.bool()
	} $else $if T is bool {
		return input
	} $else $if T is f32 || T is f64 {
		return input != 0 && !math.is_nan(f64(input))
	} $else $if T is i8 || T is i16 || T is int || T is i32 || T is i64 || T is u8 || T is u16
		|| T is u32 || T is u64 || T is isize || T is usize {
		return input != 0
	} $else $if T is big.Integer {
		return input != big.integer_from_int(0)
	} $else $if T is $array || T is $array_fixed || T is $map {
		return input.len > 0
	} $else $if T is types.Countable {
		return input.count() > 0
	} $else {
		return types.TypeError{
			message: 'Expected a boolean-convertible scalar or collection'
		}
	}
}

pub fn native_date[T](input T) !time.Time {
	$if T is $array || T is $array_fixed {
		return types.TypeError{
			message: 'Collections require an explicit date conversion'
		}
	} $else $if T is types.NativeMaybe {
		return maybe_date[T](input)
	} $else $if T is types.DateProvider {
		return dates.validated_native_date(input.to_date()!)
	} $else $if T is types.InvalidDate {
		return error('Invalid date')
	} $else $if T is big.Integer || T is types.Symbol {
		return types.TypeError{
			message: 'Cannot convert value to a number'
		}
	} $else $if T is json2.Any {
		return json_date(input)
	} $else $if T is string {
		return dates.date_from_string(input)
	} $else $if T is time.Time {
		return dates.validated_native_date(input)
	} $else $if T is types.Null {
		return types.TypeError{
			message: 'Null is not a date'
		}
	} $else $if T is types.Undefined {
		return error('Invalid date')
	} $else $if T is bool {
		return types.TypeError{
			message: 'Boolean is not a date'
		}
	} $else $if T is f32 || T is f64 {
		value := f64(input)
		// Guard conversion before narrowing; validated_native_date checks the calendar range.
		if math.is_nan(value) || math.is_inf(value, 0) || value < -31619087596800000.0
			|| value > 31494784780799999.0 {
			return error('Invalid date timestamp')
		}
		return dates.validated_native_date(dates.date_from_milliseconds(i64(value)))
	} $else $if T is i8 || T is i16 || T is int || T is i32 || T is i64 || T is u8 || T is u16
		|| T is u32 || T is u64 || T is isize || T is usize {
		// Preserve integer milliseconds beyond binary64's exact integer range.
		$if T is u8 || T is u16 || T is u32 || T is u64 || T is usize {
			if u64(input) > u64(31494784780799999) { return error('Invalid date timestamp') }
		}
		milliseconds := i64(input)
		if milliseconds < i64(-31619087596800000) || milliseconds > i64(31494784780799999) {
			return error('Invalid date timestamp')
		}
		return dates.validated_native_date(dates.date_from_milliseconds(milliseconds))
	} $else {
		$compile_error('to_date_from supports text, dates, or epoch milliseconds')
	}
}

pub fn native_string[T](input T) string {
	$if T is types.NativeMaybe {
		return maybe_string[T](input)
	} $else $if T is types.InvalidDate {
		return 'Invalid Date'
	} $else $if T is types.Null {
		return 'null'
	} $else $if T is types.Undefined {
		return 'undefined'
	} $else $if T is types.Symbol {
		return 'Symbol(' + input.description + ')'
	} $else $if T is time.Time {
		return dates.native_date_string(input) or { 'Invalid Date' }
	} $else $if T is string {
		return input
	} $else $if T is f32 {
		return numbers.native_f32_string(input)
	} $else $if T is f64 {
		return numbers.native_number_string(input)
	} $else {
		return input.str()
	}
}
