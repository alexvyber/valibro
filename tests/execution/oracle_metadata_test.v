module valibro_test

import os
import crypto.sha256
import x.json2

fn read_oracle_metadata(relative string) json2.Any {
	return json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT, relative)) or { panic(err) }) or {
		panic(err)
	}
}

fn oracle_file_hash(relative string) string {
	data := os.read_bytes(os.join_path(@VMODROOT, relative)) or { panic(err) }
	return sha256.sum(data).hex()
}

fn test_reference_manifest_and_explicit_native_case_reports() {
	manifest := read_oracle_metadata('tests/fixtures/differential_sources.json').as_map()
	selection := manifest['native_cases']!.as_map()
	assert oracle_file_hash(selection['file']!.str()) == selection['sha256']!.str()
	registry := read_oracle_metadata(selection['file']!.str()).as_map()
	corpora := registry['corpora']!.as_map()
	tags := registry['tags']!.as_map()
	mut retained := 0
	mut excluded := 0
	for item in manifest['fixtures']!.as_array() {
		fixture := item.as_map()
		assert oracle_file_hash(fixture['fixture']!.str()) == fixture['sha256']!.str()
		assert os.is_file(os.join_path(@VMODROOT, fixture['generator']!.str()))
		profile := fixture['native_profile']!.as_map()
		assert oracle_file_hash(profile['file']!.str()) == profile['sha256']!.str()
		report := read_oracle_metadata(profile['file']!.str()).as_map()
		assert report['retained_outcomes']!.int() == fixture['outcomes']!.int()
		assert report['excluded_outcomes']!.int() == profile['excluded_outcomes']!.int()
		assert report['input_outcomes']!.int() == report['retained_outcomes']!.int() +
			report['excluded_outcomes']!.int()
		assert report['input_rows']!.int() == report['retained_rows']!.int() +
			report['excluded_rows']!.int()
		corpus := report['corpus']!.str()
		mut reviewed := map[string]string{}
		for row in corpora[corpus]!.as_array() {
			reviewed[row.as_map()['id']!.str()] = row.as_map()['tag']!.str()
		}
		mut observed := map[string]bool{}
		mut rejected := 0
		for row in report['exclusions']!.as_array() {
			entry := row.as_map()
			id := entry['id']!.str()
			tag := entry['tag']!.str()
			assert id.len == 64
			assert tag in tags
			assert reviewed[id] == tag
			observed[id] = true
			rejected += entry['outcomes']!.int()
		}
		assert rejected == report['excluded_outcomes']!.int()
		assert observed.len == reviewed.len
		retained += report['retained_outcomes']!.int()
		excluded += rejected
	}
	assert retained == manifest['outcomes']!.int()
	assert excluded == manifest['excluded_outcomes']!.int()
}
