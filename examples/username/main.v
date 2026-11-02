module main

import valibro as v

fn main() {
	username := v.pipe(v.string(), v.trim(), v.to_lower_case(), v.min_length(3), v.max_length(32))
	result := v.safe_parse(username, '  Alex  ')
	if result.success {
		output := result.output or { return }
		println(output)
	} else {
		for issue in result.issues {
			println('${issue.code}: ${issue.message}')
		}
	}
}
