module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

struct MessageCalls {
mut:
	values []json2.Any
}

fn traced_message(mut calls MessageCalls, provider string) types.ErrorMessage {
	return v.message_fn(fn [mut calls, provider] (issue v.Issue) string {
		calls.values << json2.Any({
			'provider':         json2.Any(provider)
			'kind':             json2.Any(issue.kind.str())
			'code':             json2.Any(issue.code)
			'lang':             json2.Any(issue.lang)
			'abort_early':      json2.Any(issue.abort_early)
			'abort_pipe_early': json2.Any(issue.abort_pipe_early)
			'expected':         json2.Any(issue.expected)
			'received':         json2.Any(issue.received)
			'message':          json2.Any(issue.message)
		})
		return 'Selected ' + provider
	})
}

fn test_message_callback_metadata_precedence_and_call_counts_differential() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/execution/message_context_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	mut failures := 0
	for raw in rows {
		row := raw.as_map()
		mode := row['mode']!.str()
		name := row['name']!.str()
		lang := row['lang']!.str()
		mut calls := &MessageCalls{}
		factory := if mode == 'factory' {
			[traced_message(mut calls, 'factory')]
		} else {
			[]types.ErrorMessage{}
		}
		mut context := v.Context{}
		code := match name {
			'schema' { 'literal' }
			'runtime_type' { 'string' }
			'check' { 'min_length' }
			'format' { 'email' }
			'convert' { 'to_bigint' }
			'multiple' { 'multiple_of' }
			'url' { 'url' }
			'regex' { 'regex' }
			'custom_check' { 'check' }
			else { 'words' }
		}

		if mode == 'specific' {
			v.set_specific_message(mut context, code, traced_message(mut calls, 'specific'), lang)
		}
		if mode == 'schema' {
			v.set_schema_message(mut context, traced_message(mut calls, 'schema'), lang)
		}
		if mode == 'global' {
			v.set_global_message(mut context, traced_message(mut calls, 'global'), lang)
		}
		mut config := v.Config{
			...context.config
			lang:             lang
			abort_early:      row['abort_early']!.bool()
			abort_pipe_early: row['abort_pipe_early']!.bool()
		}
		if mode in ['factory', 'specific', 'schema', 'config'] { config = v.Config{
				...config
				message: traced_message(mut calls, 'config')
			} }
		mut messages := []string{}
		if name == 'multiple' {
			result := v.safe_parse_with_config(v.pipe(v.number(), v.multiple_of(2.0, ...factory)),
				row['input']!.f64(), config)
			messages = result.issues.map(it.message)
		} else if name == 'convert' {
			result := v.safe_parse_with_config(v.pipe_to(v.string(), v.to_bigint(...factory)),
				row['input']!.str(), config)
			messages = result.issues.map(it.message)
		} else {
			schema := match name {
				'schema' {
					j.from_schema(v.literal('a', ...factory))
				}
				'runtime_type' {
					j.from_schema(v.string(...factory))
				}
				'check' {
					j.from_schema(v.pipe(v.string(), v.min_length(3, ...factory)))
				}
				'format' {
					j.from_schema(v.pipe(v.string(), v.email(...factory)))
				}
				'url' {
					j.from_schema(v.pipe(v.string(), v.url(...factory)))
				}
				'regex' {
					j.from_schema(v.pipe(v.string(), v.regex('a', ...factory)))
				}
				'custom_check' {
					j.from_schema(v.pipe(v.string(), v.check(fn (input string) bool {
						return false
					}, ...factory)))
				}
				else {
					j.from_schema(v.pipe(v.string(), v.words(2, ...factory)))
				}
			}

			result := j.safe_parse_with_config(schema, row['input']!, config)
			messages = result.issues.map(it.message)
		}
		if !j.equal(json2.Any(messages.map(json2.Any(it))), row['messages']!)
			|| !j.equal(json2.Any(calls.values), row['calls']!) {
			failures++
			if failures <= 6 { eprintln('${row}: messages ${messages}; calls ${calls.values}') }
		}
	}
	assert failures == 0, '${failures} message context mismatches'
}
