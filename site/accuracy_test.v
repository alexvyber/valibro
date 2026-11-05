module main

fn api_item(module_name string, name string, receiver string) ApiSymbol {
	for item in read_inventory(@VMODROOT) or { panic(err) } {
		if item.module_name == module_name && item.name == name && item.receiver == receiver {
			return item
		}
	}
	panic('Missing API: ${module_name}.${receiver}.${name}')
}

fn test_descriptions_cover_every_public_declaration_without_placeholder_prose() {
	for item in read_inventory(@VMODROOT) or { panic(err) } {
		description := symbol_summary(item)
		assert description != '', item.id()
		assert !description.starts_with('Public '), item.id()
		assert !description.starts_with('Use `'), item.id()
		assert !description.contains('selected by `'), item.id()
	}
}

fn test_namespace_and_return_contracts_are_distinguished() {
	constructor := symbol_summary(api_item('types', 'entry_map', ''))
	validator := symbol_summary(api_item('valibro', 'entry_map', ''))
	assert constructor.contains('Construct')
	assert validator.contains('validate')
	assert constructor != validator
	assert accurate_notes(api_item('valibro', 'parse', '')).contains('ValidationError')
	assert !accurate_notes(api_item('valibro', 'parse', '')).contains('Schemas are reusable')
	assert accurate_notes(api_item('valibro', 'pipe_to', '')).contains('only when')
}

fn test_concrete_behavior_corrections_remain_documented() {
	assert accurate_notes(api_item('valibro', 'config', '')).contains('does not override')
	assert symbol_summary(api_item('valibro', 'check_items', '')).contains('separate indexed issue')
	assert symbol_summary(api_item('valibro', 'iso_date', '')).contains('not Gregorian')
	assert symbol_summary(api_item('valibro', 'jws_compact', '')).contains('verify a signature')
	assert symbol_summary(api_item('valibro', 'nanoid', '')).contains('does not enforce')
	assert symbol_summary(api_item('json', 'equal', '')).contains('integer precision')
	assert symbol_summary(api_item('types', 'native_set_equal', '')).contains('match exactly')
	assert accurate_notes(api_item('json', 'parse_text', '')).contains('ties-to-even')
	for name in ['object', 'strict_object', 'loose_object', 'object_with_rest', 'record', 'variant'] {
		assert accurate_notes(api_item('json', name, '')).to_lower().contains('arrays')
	}
}

fn test_reference_pages_include_runnable_examples_audited_apis() {
	pages := load_pages(@VMODROOT)!
	for url in ['/api/config/', '/api/parse/', '/api/inspect/', '/api/try_transform/',
		'/api/check_items/', '/api/iso_date/', '/api/bytes/', '/api/max_length_of/',
		'/api/types--contextual_action/', '/api/methods--cachedschemaio-set/'] {
		mut found := false
		for page in pages {
			if page.url == url {
				assert page.document.examples.len > 0, url
				found = true
			}
		}
		assert found, url
	}
}

fn test_examples_match_the_receiver_and_module_instead_of_only_a_method_name() {
	blob := api_item('types', 'count', 'Blob')
	assert !example_uses(blob,
		'import valibro as v\ns := types.new_set([1])\nassert s.count() == 1')
	assert example_uses(blob, 'import valibro.types\nb := types.Blob{}\nassert b.count() == 0')
	json_object := api_item('json', 'object', '')
	assert !example_uses(json_object, 'import valibro as v\nschema := v.object[User]()')
	assert example_uses(json_object,
		"import valibro.json as j\nschema := j.object({'name': j.string()})")
}

fn test_every_public_reference_has_an_inline_executable_example() {
	mut missing := []string{}
	for page in load_pages(@VMODROOT)! {
		if page.api_id != '' && page.document.examples.len == 0 { missing << page.api_id }
	}
	assert missing.len == 0, missing.join('\n')
}

fn test_removed_javascript_apis_are_not_public() {
	for item in read_inventory(@VMODROOT)! {
		assert item.name !in ['safe_parse', 'safe_parse_checked', 'safe_parse_with_config',
			'safe_parser', 'parse_async', 'safe_parse_async', 'promise', 'await_future', 'readonly',
			'readonly_for', 'brand', 'flavor', 'instance', 'to_string', 'Maybe', 'SafeParseResult',
			'Future', 'Undefined', 'Symbol', 'Branded', 'Flavored', 'Reviver', 'Replacer',
			'JsonSource'], item.id()
	}
}
