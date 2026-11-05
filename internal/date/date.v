module date

import time
import encoding.utf8

// Native ISO calendar input; an omitted offset means UTC, independent of TZ.
pub fn date_from_string(input string) !time.Time {
	return date_from_string_in(input, '')
}

pub fn date_from_string_in(input string, timezone string) !time.Time {
	default_offset := fixed_offset(timezone)!
	if !utf8.validate_str(input) || input.len < 10 || input[4] != `-` || input[7] != `-` {
		return error('Expected an ISO calendar date')
	}
	year := decimal(input, 0, 4)!
	month := decimal(input, 5, 2)!
	day := decimal(input, 8, 2)!
	mut hour := 0
	mut minute := 0
	mut second := 0
	mut nanosecond := 0
	mut offset := default_offset
	if input.len > 10 {
		if input.len < 16 || input[10] !in [`T`, `t`, ` `] || input[13] != `:` {
			return error('Expected ISO date and time')
		}
		hour = decimal(input, 11, 2)!
		minute = decimal(input, 14, 2)!
		mut pos := 16
		mut has_seconds := false
		if pos < input.len && input[pos] == `:` {
			second = decimal(input, pos + 1, 2)!
			has_seconds = true
			pos += 3
		}
		if pos < input.len && input[pos] == `.` {
			if !has_seconds { return error('Fraction requires seconds') }
			pos++
			start := pos
			for pos < input.len && input[pos] >= `0` && input[pos] <= `9` {
				if pos - start >= 9 { return error('Expected at most nine fractional digits') }
				nanosecond = nanosecond * 10 + int(input[pos] - `0`)
				pos++
			}
			if pos == start { return error('Expected fractional digits') }
			for _ in 0 .. 9 - (pos - start) {
				nanosecond *= 10
			}
		}
		if pos < input.len { offset = fixed_offset(input[pos..])! }
	}
	calendar := validated_native_date(time.Time{
		year:       year
		month:      month
		day:        day
		hour:       hour
		minute:     minute
		second:     second
		nanosecond: nanosecond
	})!
	return validated_native_date(time.unix_nanosecond(calendar.unix() - offset, nanosecond))
}

fn decimal(input string, start int, width int) !int {
	if start < 0 || start + width > input.len { return error('Incomplete date component') }
	mut value := 0
	for b in input[start..start + width].bytes() {
		if b < `0` || b > `9` { return error('Expected decimal date component') }
		value = value * 10 + int(b - `0`)
	}
	return value
}

// Only UTC and explicit offsets are supported; no timezone database is needed.
fn fixed_offset(zone string) !i64 {
	if zone in ['', 'UTC', 'Etc/UTC', 'Z', 'z'] { return 0 }
	if zone.len != 6 || zone[0] !in [`+`, `-`] || zone[3] != `:` {
		return error('Expected UTC or a fixed offset such as +02:00')
	}
	hour := decimal(zone, 1, 2)!
	minute := decimal(zone, 4, 2)!
	if hour > 23 || minute > 59 { return error('Invalid timezone offset') }
	offset := i64(hour * 3600 + minute * 60)
	return if zone[0] == `-` { -offset } else { offset }
}

pub fn date_from_milliseconds(milliseconds i64) time.Time {
	// V 0.5.2's unix_milli truncates division and leaves negative nanoseconds.
	mut seconds := milliseconds / 1000
	mut remainder := milliseconds % 1000
	if remainder < 0 {
		seconds--
		remainder += 1000
	}
	return time.unix_nanosecond(seconds, int(remainder * 1000000))
}

// Supported calendar years are -999999 through 999999, within V 0.5.2's
// date conversion arithmetic and the signed millisecond representation.
// Gregorian calendar arithmetic independent of V's cached field conversion.
// In V 0.5.2 that conversion is one day off in some years before year one.
pub fn calendar_seconds(year int, month int, day int, hour int, minute int, second int) i64 {
	y := i64(year) - if month <= 2 { i64(1) } else { i64(0) }
	era := if y >= 0 { y / 400 } else { (y - 399) / 400 }
	yoe := y - era * 400
	m := i64(month) + if month > 2 { i64(-3) } else { i64(9) }
	doy := (153 * m + 2) / 5 + day - 1
	doe := yoe * 365 + yoe / 4 - yoe / 100 + doy
	return (era * 146097 + doe - 719468) * 86400 + i64(hour) * 3600 + minute * 60 + second
}

pub fn validated_native_date(input time.Time) !time.Time {
	days := time.days_in_month(input.month, input.year) or { 0 }
	if input.year < -999999 || input.year > 999999 || days == 0 || input.day < 1 || input.day > days
		|| input.hour < 0 || input.hour > 23 || input.minute < 0 || input.minute > 59
		|| input.second < 0 || input.second > 59 || input.nanosecond < 0
		|| input.nanosecond >= 1_000_000_000 {
		return error('Invalid date')
	}
	rebuilt := time.Time{
		...time.unix_nanosecond(calendar_seconds(input.year, input.month, input.day, input.hour,
			input.minute, input.second), input.nanosecond)
		is_local: input.is_local
	}
	return rebuilt
}

pub fn native_date_string(input time.Time) !string {
	return native_date_string_in(input, '')
}

pub fn native_date_string_in(input time.Time, timezone string) !string {
	offset := fixed_offset(timezone)!
	valid := validated_native_date(input) or { return 'Invalid Date' }
	local := time.unix_nanosecond(valid.unix() + offset, valid.nanosecond)
	year := if local.year >= 0 && local.year <= 9999 {
		'${local.year:04}'
	} else if local.year < 0 {
		'-${-local.year:06}'
	} else {
		'+${local.year:06}'
	}
	fraction := if local.nanosecond % 1_000_000 == 0 {
		'${local.nanosecond / 1_000_000:03}'
	} else {
		'${local.nanosecond:09}'
	}
	absolute := if offset < 0 { -offset } else { offset }
	sign := if offset < 0 { '-' } else { '+' }
	suffix := if offset == 0 {
		'Z'
	} else {
		'${sign}${absolute / 3600:02}:${(absolute % 3600) / 60:02}'
	}
	return '${year}-${local.month:02}-${local.day:02}T${local.hour:02}:${local.minute:02}:${local.second:02}.${fraction}${suffix}'
}
