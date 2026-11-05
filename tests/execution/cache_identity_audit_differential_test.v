module valibro_test

import valibro.tests.support
import os
import x.json2
import valibro as v

struct IdentityAuditCounts {
mut:
	validations int
	calls       []int = [0, 0]
}

fn test_message_callback_identity_cache_hits_and_eviction_match_valibot() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/execution/cache_identity_audit_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		mut counts := &IdentityAuditCounts{}
		mut callbacks := []v.ErrorMessage{}
		for id in 0 .. 2 {
			callbacks << v.message_fn(fn [mut counts, id] (issue v.Issue) string {
				counts.calls[id]++
				return '${id}:${issue.received}'
			})
		}
		schema := v.cache(v.pipe(v.string(), v.check(fn [mut counts] (value string) bool {
			counts.validations++
			return false
		})), fn (input string) string {
			return input
		}, max_size: row['capacity']!.int())
		for raw_step in row['steps']!.as_array() {
			step := raw_step.as_map()
			result := support.observe(schema, step['input']!.str(), v.Config{
				lang:    step['lang']!.str()
				message: callbacks[step['id']!.int()]
			})
			assert counts.validations == step['validations']!.int(), step.str()
			assert counts.calls == step['calls']!.as_array().map(it.int()), step.str()
			assert result.issues.map(it.message) == step['messages']!.as_array().map(it.str()), step.str()
		}
	}
}
