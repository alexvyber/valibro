module coercion

import valibro.internal.date as dates
import valibro.internal.number as numbers
import x.json2
import math
import math.big
import time
import valibro.types

// Use statement matches here: V 0.5.2 miscompiles an if expression nested in
// an array append inside a Result-valued match expression.
pub fn json_string(value json2.Any) !string {
	match value {
		json2.Null {
			return 'null'
		}
		string {
			return value
		}
		bool {
			return value.str()
		}
		time.Time {
			return dates.native_date_string(value)
		}
		f64 {
			return numbers.native_number_string(value)
		}
		f32 {
			return numbers.native_f32_string(value)
		}
		else {
			return value.str()
		}
	}
}

pub fn json_number(value json2.Any) !f64 {
	if types.is_json_number(value) {
		number := value.f64()
		if math.is_nan(number) { return error('NaN') }
		return number
	}
	if value is time.Time { return native_number[time.Time](value) }
	match value {
		json2.Null {
			return types.TypeError{
				message: 'Null is not a number'
			}
		}
		bool {
			if value { return 1.0 }
			return 0.0
		}
		string {
			return numbers.number_from_string(value)
		}
		f64 {
			if math.is_nan(value) { return error('NaN') }
			return value
		}
		f32 {
			if math.is_nan(f64(value)) { return error('NaN') }
			return f64(value)
		}
		int {
			return f64(value)
		}
		i64 {
			return f64(value)
		}
		u64 {
			return f64(value)
		}
		else {
			return types.TypeError{
				message: 'Expected a numeric scalar'
			}
		}
	}
}

pub fn json_bigint(value json2.Any) !big.Integer {
	if value is string { return numbers.bigint_from_string(value) }
	if value is time.Time { return native_bigint[time.Time](value) }
	match value {
		i8 {
			return native_bigint[i8](value)
		}
		i16 {
			return native_bigint[i16](value)
		}
		i32 {
			return native_bigint[i32](value)
		}
		u8 {
			return native_bigint[u8](value)
		}
		u16 {
			return native_bigint[u16](value)
		}
		u32 {
			return native_bigint[u32](value)
		}
		json2.Null {
			return error('Null is not a bigint')
		}
		bool {
			if value { return big.integer_from_int(1) }
			return big.integer_from_int(0)
		}
		int {
			return big.integer_from_int(value)
		}
		i64 {
			return big.integer_from_string(value.str())
		}
		u64 {
			return big.integer_from_string(value.str())
		}
		f64 {
			return native_bigint[f64](value)
		}
		f32 {
			return native_bigint[f32](value)
		}
		else {
			return types.TypeError{
				message: 'Expected an integer scalar'
			}
		}
	}
}

pub fn json_boolean(value json2.Any) !bool {
	if types.is_json_number(value) {
		n := value.f64()
		return n != 0 && !math.is_nan(n)
	}
	return match value {
		json2.Null {
			false
		}
		bool {
			value
		}
		string {
			value.bool()
		}
		int {
			value != 0
		}
		i64 {
			value != 0
		}
		u64 {
			value != 0
		}
		f32 {
			value != 0 && !math.is_nan(f64(value))
		}
		f64 {
			value != 0 && !math.is_nan(value)
		}
		[]json2.Any {
			value.len > 0
		}
		map[string]json2.Any {
			value.len > 0
		}
		else {
			return types.TypeError{
				message: 'Expected a boolean-convertible scalar or collection'
			}
		}
	}
}

pub fn json_date(value json2.Any) !time.Time {
	if value is time.Time { return dates.validated_native_date(value) }
	match value {
		i8 {
			return native_date[i8](value)
		}
		i16 {
			return native_date[i16](value)
		}
		i32 {
			return native_date[i32](value)
		}
		u8 {
			return native_date[u8](value)
		}
		u16 {
			return native_date[u16](value)
		}
		u32 {
			return native_date[u32](value)
		}
		json2.Null {
			return types.TypeError{
				message: 'Null is not a date'
			}
		}
		bool {
			return types.TypeError{
				message: 'Boolean is not a date'
			}
		}
		int {
			return native_date[int](value)
		}
		i64 {
			return native_date[i64](value)
		}
		u64 {
			return native_date[u64](value)
		}
		f64 {
			return native_date[f64](value)
		}
		f32 {
			return native_date[f32](value)
		}
		else {
			if value is string { return dates.date_from_string(value) }
			return types.TypeError{
				message: 'Expected a date scalar'
			}
		}
	}
}
