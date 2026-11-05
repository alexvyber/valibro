module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

fn collection_action[T](action string, req json2.Any, messages []types.ErrorMessage) types.Action[T] {
	if action == 'mimeType' {
		$if T is types.Blob || T is types.File {
			return v.mime_type[T](req.as_array().map(it.str()), ...messages)
		} $else {
			panic(action)
		}
	}
	n := req.int()
	return match action {
		'entries' {
			v.entries[T](n, ...messages)
		}
		'minEntries' {
			v.min_entries[T](n, ...messages)
		}
		'maxEntries' {
			v.max_entries[T](n, ...messages)
		}
		'notEntries' {
			v.not_entries[T](n, ...messages)
		}
		'size' {
			v.size[T](n, ...messages)
		}
		'minSize' {
			v.min_size[T](n, ...messages)
		}
		'maxSize' {
			v.max_size[T](n, ...messages)
		}
		'notSize' {
			v.not_size[T](n, ...messages)
		}
		else {
			panic(action)
		}
	}
}

fn collection_issues[T](input T, action types.Action[T], config v.Config) []types.Issue {
	return v.safe_parse_with_config[T, T](v.pipe(v.unknown[T](), action), input, config).issues
}

fn test_collection_measurements_mime_and_item_issues_differential() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/collections/collection_action_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	mut failures := 0
	for raw in rows {
		row := raw.as_map()
		action := row['action']!.str()
		req := row['requirement']!
		mode := row['mode']!.str()
		messages := if mode == 'factory' {
			[types.ErrorMessage('Factory message')]
		} else {
			[]types.ErrorMessage{}
		}
		config := if mode == 'config' {
			v.Config{
				message: types.ErrorMessage('Config message')
			}
		} else {
			v.Config{}
		}
		mut issues := []types.Issue{}
		match row['domain']!.str() {
			'object' {
				input := row['input']!.as_map()
				issues = collection_issues[map[string]json2.Any](input, collection_action[map[string]json2.Any](action,
					req, messages), config)
			}
			'map' {
				mut input := map[string]int{}
				for entry in row['input']!.as_array() {
					pair := entry.as_array()
					input[pair[0].str()] = pair[1].int()
				}
				issues = collection_issues[map[string]int](input, collection_action[map[string]int](action,
					req, messages), config)
			}
			'set' {
				input := types.new_set(row['input']!.as_array().map(it.int()))
				issues = collection_issues[types.Set[int]](input, collection_action[types.Set[int]](action,
					req, messages), config)
			}
			'blob' {
				input := types.Blob{
					data:      row['input']!.str().bytes()
					mime_type: 'text/plain'
				}
				issues = collection_issues[types.Blob](input, collection_action[types.Blob](action,
					req, messages), config)
			}
			'file' {
				input := types.File{
					data:      row['input']!.str().bytes()
					mime_type: 'text/plain'
					name:      'x'
				}
				issues = collection_issues[types.File](input, collection_action[types.File](action,
					req, messages), config)
			}
			else {
				input := row['input']!.as_array().map(it.int())
				predicate := fn (value int, index int) bool {
					return value % 2 == 0 && index < 3
				}
				check := match action {
					'everyItem' { v.every_item[int](predicate, ...messages) }
					'someItem' { v.some_item[int](predicate, ...messages) }
					'checkItems' { v.check_items[int](predicate, ...messages) }
					'includes' { v.includes_item[int](req.int(), ...messages) }
					else { v.excludes_item[int](req.int(), ...messages) }
				}

				issues = collection_issues[[]int](input, check, config)
			}
		}

		mut actual := []json2.Any{}
		for issue in issues {
			mut path := []json2.Any{}
			for key in issue.path {
				match key {
					int { path << json2.Any(key) }
					string { path << json2.Any(key) }
				}
			}
			actual << json2.Any({
				'code':     json2.Any(issue.code)
				'expected': json2.Any(issue.expected)
				'received': json2.Any(issue.received)
				'message':  json2.Any(issue.message)
				'path':     json2.Any(path)
			})
		}
		if (issues.len == 0) != row['success']!.bool()
			|| !j.equal(json2.Any(actual), row['issues']!) {
			failures++
			if failures <= 6 { eprintln('${row}: got ${actual}') }
		}
	}
	assert failures == 0, '${failures} collection action mismatches'
}
