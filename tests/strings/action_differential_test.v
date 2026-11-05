module valibro_test

import math
import os
import x.json2
import valibro as v
import valibro.types

fn differential_number(input json2.Any) f64 {
	if input is string {
		return match input {
			'NaN' { math.nan() }
			'Infinity' { math.inf(1) }
			'-Infinity' { math.inf(-1) }
			'-0' { -0.0 }
			else { panic(input) }
		}
	}
	return input.f64()
}

fn differential_string_action(name string, req json2.Any, messages []types.ErrorMessage) types.Action[string] {
	n := req.int()
	s := req.str()
	return match name {
		'length' { v.length(n, ...messages) }
		'minLength' { v.min_length(n, ...messages) }
		'maxLength' { v.max_length(n, ...messages) }
		'notLength' { v.not_length(n, ...messages) }
		'bytes' { v.bytes(n, ...messages) }
		'minBytes' { v.min_bytes(n, ...messages) }
		'maxBytes' { v.max_bytes(n, ...messages) }
		'notBytes' { v.not_bytes(n, ...messages) }
		'codePoints' { v.code_points(n, ...messages) }
		'minCodePoints' { v.min_code_points(n, ...messages) }
		'maxCodePoints' { v.max_code_points(n, ...messages) }
		'notCodePoints' { v.not_code_points(n, ...messages) }
		'graphemes' { v.graphemes(n, ...messages) }
		'minGraphemes' { v.min_graphemes(n, ...messages) }
		'maxGraphemes' { v.max_graphemes(n, ...messages) }
		'notGraphemes' { v.not_graphemes(n, ...messages) }
		'words' { v.words(n, ...messages) }
		'minWords' { v.min_words(n, ...messages) }
		'maxWords' { v.max_words(n, ...messages) }
		'notWords' { v.not_words(n, ...messages) }
		'empty' { v.empty(...messages) }
		'nonEmpty' { v.non_empty(...messages) }
		'startsWith' { v.starts_with(s, ...messages) }
		'endsWith' { v.ends_with(s, ...messages) }
		'includes' { v.includes(s, ...messages) }
		'excludes' { v.excludes(s, ...messages) }
		'minValue' { v.min_value(s, ...messages) }
		'maxValue' { v.max_value(s, ...messages) }
		'gtValue' { v.gt_value(s, ...messages) }
		'ltValue' { v.lt_value(s, ...messages) }
		'value' { v.value(s, ...messages) }
		'notValue' { v.not_value(s, ...messages) }
		'values' { v.values(req.as_array().map(it.str()), ...messages) }
		'notValues' { v.not_values(req.as_array().map(it.str()), ...messages) }
		else { panic(name) }
	}
}

fn differential_number_action(name string, req json2.Any, messages []types.ErrorMessage) types.Action[f64] {
	n := differential_number(req)
	return match name {
		'finite' { v.finite(...messages) }
		'integer' { v.integer(...messages) }
		'safeInteger' { v.safe_integer(...messages) }
		'minValue' { v.min_value(n, ...messages) }
		'maxValue' { v.max_value(n, ...messages) }
		'gtValue' { v.gt_value(n, ...messages) }
		'ltValue' { v.lt_value(n, ...messages) }
		'value' { v.value(n, ...messages) }
		'notValue' { v.not_value(n, ...messages) }
		'multipleOf' { v.multiple_of(n, ...messages) }
		'values' { v.values(req.as_array().map(differential_number(it)), ...messages) }
		'notValues' { v.not_values(req.as_array().map(differential_number(it)), ...messages) }
		else { panic(name) }
	}
}

fn differential_array_action(name string, req json2.Any, messages []types.ErrorMessage) types.Action[[]json2.Any] {
	n := req.int()
	return match name {
		'length' { v.length_of[[]json2.Any](n, ...messages) }
		'minLength' { v.min_length_of[[]json2.Any](n, ...messages) }
		'maxLength' { v.max_length_of[[]json2.Any](n, ...messages) }
		'notLength' { v.not_length_of[[]json2.Any](n, ...messages) }
		'empty' { v.empty_of[[]json2.Any](...messages) }
		'nonEmpty' { v.non_empty_of[[]json2.Any](...messages) }
		else { panic(name) }
	}
}

fn test_differential_action_results_and_issue_fields() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/strings/action_differential.json')) or { panic(err) }) or { panic(err) }).as_array()
	mut failures := 0
	mut categories := map[string]int{}
	mut diagnostics := []json2.Any{}
	for raw in rows {
		row := raw.as_map()
		action := row['action']!.str()
		mode := row['mode']!.str()
		messages := if mode == 'factory' {
			[types.ErrorMessage('Factory message')]
		} else {
			[]types.ErrorMessage{}
		}
		settings := if mode == 'config' {
			v.Config{
				message: types.ErrorMessage('Config message')
			}
		} else {
			v.Config{}
		}
		req := row['requirement']!
		input := row['input']!
		mut success := false
		mut issues := []types.Issue{}
		match row['domain']!.str() {
			'string' {
				result := v.safe_parse_with_config(v.pipe(v.string(), differential_string_action(action,
					req, messages)), input.str(), settings)
				success = result.success
				issues = result.issues.clone()
			}
			'number' {
				result := v.safe_parse_with_config(v.pipe(v.unknown[f64](), differential_number_action(action,
					req, messages)), differential_number(input), settings)
				success = result.success
				issues = result.issues.clone()
			}
			'array' {
				result := v.safe_parse_with_config(v.pipe(v.unknown[[]json2.Any](), differential_array_action(action,
					req, messages)), input.as_array(), settings)
				success = result.success
				issues = result.issues.clone()
			}
			else {
				panic('domain')
			}
		}

		mut reason := ''
		if success != row['success']!.bool() {
			reason = 'success'
		} else if !success {
			actual := issues[0]
			if actual.code != row['code']!.str() {
				reason = 'code'
			} else if types.utf16_units(actual.expected) != row['expected']!.as_array().map(u16(it.int())) {
				reason = 'expected'
			} else if actual.received_units() != row['received']!.as_array().map(u16(it.int())) {
				reason = 'received'
			} else if actual.message_units() != row['message']!.as_array().map(u16(it.int())) {
				reason = 'message'
			}
		}
		if reason != '' {
			failures++
			categories[action + ':' + reason]++
			diagnostics << json2.Any({
				'row':    json2.Any(row)
				'reason': json2.Any(reason)
				'actual': json2.Any(issues.str())
			})
			if failures <= 8 { eprintln('${reason}: ${row}; got ${issues}') }
		}
	}
	if report := os.getenv_opt('VALIBRO_ACTION_REPORT') { os.write_file(report, json2.encode(diagnostics)) or {
			panic(err)} }
	assert failures == 0, '${failures} mismatches: ${categories}'
}

fn test_native_error_fragments_keep_whole_code_points() {
	result := v.safe_parse(v.pipe(v.string(), v.starts_with('a')), '🙂')
	issue := result.issues[0]
	assert issue.received == '"🙂"'
	assert issue.received_units() == types.utf16_units('"🙂"')
	assert issue.message_units() == types.utf16_units('Invalid start: Expected "a" but received "🙂"')
	wrapped := v.pipe(v.string(), v.message(v.starts_with('a'), 'Wrapped'))
	assert v.safe_parse(wrapped, '🙂').issues[0].message_units() == types.utf16_units('Wrapped')
}
