module coercion

import valibro.internal.date as dates
import valibro.types
import time
import x.json2

pub fn native_string_checked[T](input T) !string {
	$if T is types.StringProvider {
		return input.to_string()
	} $else $if T is time.Time {
		return dates.native_date_string(input)
	} $else $if T is json2.Any {
		return json_string(input)
	} $else {
		return native_string[T](input)
	}
}
