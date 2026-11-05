module main

import os

fn extra_example_programs(root string) ![]string {
	mut programs := []string{}
	mut files := os.walk_ext(os.join_path(root, 'docs/examples'), '.vv')
	files.sort()
	for file in files {
		programs << os.read_file(file)!
	}
	return programs
}

fn reference_example(item ApiSymbol, authored []Page, extra []string) string {
	if item.kind == 'function' && item.module_name in ['valibro', 'actions'] {
		format := format_example(item.name)
		if format != '' { return format }
		measured := measurement_example(item.name)
		if measured != '' { return measured }
	}
	for code in extra {
		if example_uses(item, code) { return code }
	}
	for page in authored {
		for code in page.document.examples {
			if example_uses(item, code) { return code }
		}
	}
	return ''
}

fn example_uses(item ApiSymbol, code string) bool {
	if item.kind == 'method' {
		if item.name.ends_with('.from') {
			return code.contains(item.name + '(') || code.contains(item.name + '[')
		}
		return code.contains('.${item.name}(')
			&& example_has_receiver(item.receiver.all_before('['), code)
	}
	prefixes := match item.module_name {
		'valibro' { ['v.'] }
		'json' { ['j.', 'json.'] }
		'types' { ['types.'] }
		'jsoncodec' { ['jsoncodec.'] }
		'unicode' { ['unicode.'] }
		else { ['${item.module_name}.', 'v.'] }
	}

	if item.kind !in ['function', 'method'] && representation_example(item, code) { return true }
	if item.kind !in ['function', 'method'] {
		for prefix in prefixes {
			for suffix in [')', ',', ' ', '\n', '.'] {
				if code.contains(prefix + item.name + suffix) { return true }
			}
		}
	}
	for prefix in prefixes {
		for suffix in ['(', '[', '{'] {
			if code.contains(prefix + item.name + suffix)
				|| code.contains(prefix + item.name + ' ' + suffix) {
				return true
			}
		}
	}
	return false
}

fn measurement_example(name string) string {
	mut base := name
	mut relation := 'equal'
	for prefix in ['min_', 'max_', 'not_'] {
		if name.starts_with(prefix) {
			base = name[prefix.len..]
			relation = prefix.trim_right('_')
			break
		}
	}
	short := if relation in ['max', 'not'] { true } else { false }
	if base in ['length', 'bytes', 'code_points', 'graphemes', 'words'] {
		long := if base == 'words' { 'one two three' } else { 'abc' }
		small := if base == 'words' { 'one two' } else { 'ab' }
		good := if short { small } else { long }
		bad := if short { long } else { small }
		requirement := if relation == 'max' { 2 } else { 3 }
		return "import valibro as v\n\nschema := v.pipe(v.string(), v.${name}(${requirement}))\nassert v.is_valid(schema, '${good}')!\nassert !v.is_valid(schema, '${bad}')!\n"
	}
	if base == 'length_of' {
		good := if short { '[1]' } else { '[1, 2]' }
		bad := if short { '[1, 2]' } else { '[1]' }
		requirement := if relation == 'max' { 1 } else { 2 }
		return 'import valibro as v\n\nschema := v.pipe(v.array(v.number_of[int]()), v.${name}[[]int](${requirement}))\nassert v.is_valid(schema, ${good})!\nassert !v.is_valid(schema, ${bad})!\n'
	}
	if base in ['entries', 'size'] {
		good := if short { "{'a': 1}" } else { "{'a': 1, 'b': 2}" }
		bad := if short { "{'a': 1, 'b': 2}" } else { "{'a': 1}" }
		requirement := if relation == 'max' { 1 } else { 2 }
		return 'import valibro as v\n\nschema := v.pipe(v.record(v.string(), v.number_of[int]()), v.${name}[map[string]int](${requirement}))\nassert v.is_valid(schema, ${good})!\nassert !v.is_valid(schema, ${bad})!\n'
	}
	return ''
}

fn example_has_receiver(receiver string, code string) bool {
	if code.contains('types.' + receiver) || code.contains('methods.' + receiver)
		|| code.contains('jsoncodec.' + receiver) {
		return true
	}
	constructors := {
		'CachedSchema': ['v.cached(', 'methods.cached(']
		'Set':          ['types.new_set(', 'types.new_set_with(']
		'EntryMap':     ['types.entry_map(']
		'Issue':        ['types.new_issue(', 'types.issue_of_kind(', 'types.schema_issue(']
	}
	for constructor in constructors[receiver] {
		if code.contains(constructor) { return true }
	}
	return false
}

fn representation_example(item ApiSymbol, code string) bool {
	if item.module_name == 'valibro' && item.kind == 'typedef' {
		target := item.declaration.all_after(' = ')
		for suffix in ['(', '[', '{', ' ', ')', '.', ','] {
			if code.contains(target + suffix) { return true }
		}
	}
	name := item.name
	if item.module_name !in ['types', 'methods', 'valibro'] { return false }
	producers := {
		'CachedSchema':       ['v.cached(', 'methods.cached(']
		'FlatErrors':         ['v.flatten(', 'methods.flatten(']
		'Action':             ['v.min_length(', 'types.contextual_action[']
		'EntryMap':           ['types.entry_map(']
		'Field':              ['v.field[', 'v.field(']
		'MessageCallback':    ['types.identified_message(']
		'NativeValue':        ['types.value_of[', 'types.value_of(']
		'ParseBooleanConfig': ['v.ParseBooleanConfig{']
		'Set':                ['types.new_set(', 'types.new_set_with(']
		'Transformation':     ['v.to_number(', 'v.transform_to(']
		'Regex':              ['v.compile_regex(']
		'ErrorMessage':       ['types.identified_message(', 'v.message_fn(']
	}
	for producer in producers[name] {
		if code.contains(producer) { return true }
	}
	return false
}
