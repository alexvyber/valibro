module diagnostics

import valibro.internal.coercion as coerce
import valibro.internal.number as numbers
import x.json2
import math.big
import time
import valibro.types

pub fn issue_value[T](input T) string {
	$if T is $pointer {
		if input == unsafe { nil } { return 'null' }
		return issue_value(*input)
	} $else $if T is json2.Any {
		return match input {
			string { '"' + input + '"' }
			json2.Null { 'null' }
			time.Time { 'Date' }
			f64 { numbers.native_number_string(input) }
			f32 { numbers.native_f32_string(input) }
			map[string]json2.Any { 'Object' }
			[]json2.Any { 'Array' }
			else { input.str() }
		}
	} $else $if T is big.Integer {
		return input.str()
	} $else $if T is time.Time || T is types.InvalidDate {
		return 'Date'
	} $else $if T is $function {
		return 'Function'
	} $else $if T is types.Blob {
		return 'Blob'
	} $else $if T is types.File {
		return 'File'
	} $else $if T is $array || T is $array_fixed {
		return 'Array'
	} $else $if T is $map {
		return 'Object'
	} $else $if T is string {
		return '"' + input + '"'
	} $else $if T is $struct {
		return 'Object'
	} $else {
		return coerce.native_string[T](input)
	}
}

pub fn joined_values[T](items []T) string {
	mut values := []string{}
	for item in items {
		text := value_label[T](item)
		if text !in values { values << text }
	}
	return join_expects(values)
}

pub fn join_expects(items []string) string {
	mut values := []string{}
	for item in items {
		if item !in values { values << item }
	}
	if values.len == 0 { return 'never' }
	if values.len == 1 { return values[0] }
	return '(' + values.join(' | ') + ')'
}

pub fn value_label[T](input T) string {
	$if T is time.Time {
		date := time.unix_nanosecond(input.unix(), input.nanosecond)
		year := if date.year >= 0 && date.year <= 9999 {
			'${date.year:04}'
		} else if date.year < 0 {
			'-${-date.year:06}'
		} else {
			'+${date.year:06}'
		}
		fraction := if date.nanosecond % 1_000_000 == 0 {
			'${date.nanosecond / 1_000_000:03}'
		} else {
			'${date.nanosecond:09}'
		}
		return '${year}-${date.month:02}-${date.day:02}T${date.hour:02}:${date.minute:02}:${date.second:02}.${fraction}Z'
	} $else {
		return issue_value[T](input)
	}
}
