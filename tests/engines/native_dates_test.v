module valibro_test

import valibro.internal.date as impl_date
import os
import time
import valibro as v
import valibro.types

fn test_native_iso_date_parsing_and_precision() {
	schema := v.pipe_to(v.string(), v.to_date())
	for input in ['1970-01-01', '1970-01-01T00:00Z', '1970-01-01 00:00:00Z',
		'1970-01-01T02:30:00+02:30', '1969-12-31T19:00:00-05:00'] {
		value := v.parse(schema, input) or { panic('${input}: ${err}') }
		assert value.unix_milli() == 0, input
	}
	before := v.parse(schema, '1969-12-31T23:59:59.999Z') or { panic(err) }
	assert before.unix_milli() == -1
	precise := v.parse(schema, '2000-02-29T12:34:56.123456789+02:30') or { panic(err) }
	assert precise.year == 2000 && precise.month == 2 && precise.day == 29
	assert precise.hour == 10 && precise.minute == 4 && precise.second == 56
	assert precise.nanosecond == 123456789
	assert impl_date.native_date_string(precise) or { panic(err) } == '2000-02-29T10:04:56.123456789Z'
}

fn test_native_dates_reject_legacy_and_invalid_calendars() {
	schema := v.pipe_to(v.string(), v.to_date())
	for input in ['', '42', '1/2/2020', 'Jan 2 2024', 'Tue, 02 Jan 2024 03:04:05 GMT', '2023-02-29',
		'2024-02-30', '2024-13-01', '2024-00-01', '2024-01-00', '2024-1-2', '2024-01-01T24:00:00Z',
		'2024-01-01T12:60:00Z', '2024-01-01T12:00:60Z', '2024-01-01T12:00:00+24:00',
		'2024-01-01T12:00:00+02:60', '2024-01-01T12:00:00+0200', '2024-01-01T12:00:00.Z',
		'2024-01-01T12:00:00.1234567890Z', '2024-01-01T12:00.5Z', '2024-01-01T12:00:00Zjunk',
		'+010000-01-01', ' 2024-01-01', '2024-01-01\n'] {
		result := v.safe_parse(schema, input)
		assert !result.success, input
		assert result.issues[0].code == 'to_date'
		assert types.value_is[types.InvalidDate](result.raw_output)
	}
}

fn test_native_date_timezone_is_explicit_and_deterministic() {
	old := os.getenv_opt('TZ')
	defer {
		if zone := old {
			os.setenv('TZ', zone, true)
		} else {
			os.unsetenv('TZ')
		}
	}
	for zone in ['UTC', 'America/New_York', 'Europe/Moscow'] {
		os.setenv('TZ', zone, true)
		value := impl_date.date_from_string('1970-01-01T00:00:00') or { panic(err) }
		assert value.unix_milli() == 0
		assert impl_date.native_date_string(value) or { panic(err) } == '1970-01-01T00:00:00.000Z'
	}
	shifted := impl_date.date_from_string_in('1970-01-01T00:00:00', '+02:30') or { panic(err) }
	assert shifted.unix_milli() == -9000000
	assert impl_date.native_date_string_in(time.unix(0), '+02:30') or { panic(err) } == '1970-01-01T02:30:00.000+02:30'
	if _ := impl_date.date_from_string_in('2024-01-01', 'America/New_York') { assert false
	 }
	if _ := impl_date.native_date_string_in(time.unix(0), 'Europe/Moscow') { assert false
	 }
}

fn test_native_date_adapters_and_numeric_inputs() {
	for milliseconds in [i64(-8640000000000000), -1001, -1000, -999, -1, 0, 1, 8640000000000000] {
		converted := v.parse(v.pipe_to(v.number_of[i64](), v.to_date_from[i64]()), milliseconds) or {
			panic(err)
		}
		assert converted.unix_milli() == milliseconds
		assert converted.nanosecond >= 0 && converted.nanosecond < 1000000000
	}
	input := types.some('2024-02-29')
	assert v.safe_parse(v.pipe_to(v.unknown[types.Maybe[string]](),
		v.to_date_from[types.Maybe[string]]()), input).success
	assert !v.safe_parse(v.pipe_to(v.unknown[[]string](), v.to_date_from[[]string]()), [
		'2024-02-29',
	]).success
	assert !v.safe_parse(v.pipe_to(v.unknown[[]string](), v.to_date_from[[]string]()), [
		'42',
	]).success
	parsed := impl_date.date_from_string(types.utf16_display(types.utf16_units('1970-01-01'))) or {
		panic(err)
	}
	assert parsed.unix_milli() == 0
	if _ := impl_date.date_from_string(types.utf16_display([u16(0xd800)])) { assert false
	 }
}

fn test_native_iso_fractional_widths_and_calendar_edges() {
	for digits, expected in {
		'1':         100000000
		'12':        120000000
		'123':       123000000
		'1234':      123400000
		'12345':     123450000
		'123456':    123456000
		'1234567':   123456700
		'12345678':  123456780
		'123456789': 123456789
	} {
		parsed := impl_date.date_from_string('1970-01-01T00:00:00.${digits}Z') or { panic(err) }
		assert parsed.nanosecond == expected
	}
	for input in ['0000-02-29', '2000-02-29', '2400-02-29', '9999-12-31'] {
		assert v.safe_parse(v.pipe_to(v.string(), v.to_date()), input).success, input
	}
	for input in ['1900-02-29', '2100-02-29', '2024-04-31', '2024-06-31', '2024-09-31', '2024-11-31'] {
		assert !v.safe_parse(v.pipe_to(v.string(), v.to_date()), input).success, input
	}
	beyond := impl_date.date_from_string('9999-12-31T23:59:59-23:59') or { panic(err) }
	assert beyond.year == 10000 && beyond.month == 1 && beyond.day == 1
	assert impl_date.native_date_string(time.Time{}) or { panic(err) } == 'Invalid Date'
}
