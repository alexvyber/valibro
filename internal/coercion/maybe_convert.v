module coercion

import valibro.types
import math.big
import time

fn maybe_number[T](input T) !f64 {
	$if T is types.NativeMaybe {
		if input.state == .null { return types.TypeError{
				message: 'Null is not a number'
			} }
		if input.state in [.missing, .undefined] { return error('NaN') }
		$for field in T.fields {
			$if field.name == 'value' { return native_number(input.$(field.name)) }
		}
	}
	return error('Native Maybe has no value field')
}

fn maybe_bigint[T](input T) !big.Integer {
	$if T is types.NativeMaybe {
		if input.state != .value { return types.TypeError{
				message: 'Cannot convert value to BigInt'
			} }
		$for field in T.fields {
			$if field.name == 'value' { return native_bigint(input.$(field.name)) }
		}
	}
	return error('Native Maybe has no value field')
}

fn maybe_boolean[T](input T) !bool {
	$if T is types.NativeMaybe {
		if input.state != .value { return false }
		$for field in T.fields {
			$if field.name == 'value' { return native_boolean(input.$(field.name)) }
		}
	}
	return false
}

fn maybe_date[T](input T) !time.Time {
	$if T is types.NativeMaybe {
		if input.state == .null { return types.TypeError{
				message: 'Null is not a date'
			} }
		if input.state in [.missing, .undefined] { return error('Invalid date') }
		$for field in T.fields {
			$if field.name == 'value' { return native_date(input.$(field.name)) }
		}
	}
	return error('Native Maybe has no value field')
}

fn maybe_string[T](input T) string {
	$if T is types.NativeMaybe {
		if input.state == .null { return 'null' }
		if input.state in [.missing, .undefined] { return 'undefined' }
		$for field in T.fields {
			$if field.name == 'value' { return native_string(input.$(field.name)) }
		}
	}
	return 'Object'
}

fn maybe_string_checked[T](input T) !string {
	$if T is types.NativeMaybe {
		if input.state == .null { return 'null' }
		if input.state in [.missing, .undefined] { return 'undefined' }
		$for field in T.fields {
			$if field.name == 'value' { return native_string_checked(input.$(field.name)) }
		}
	}
	return error('Native Maybe has no value field')
}
