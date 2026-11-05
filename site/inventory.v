module main

import os
import x.json2

const api_modules = ['valibro', 'schemas', 'actions', 'methods', 'types', 'json', 'jsoncodec',
	'storages', 'unicode']

struct ApiSymbol {
	module_name string
	name        string
	receiver    string
	kind        string
	declaration string
	comment     string
	file        string
	line        int
}

fn (item ApiSymbol) id() string {
	return '${item.module_name}:${item.receiver}:${item.kind}:${item.name}'
}

fn (item ApiSymbol) label() string {
	return if item.receiver == '' { item.name } else { '${item.receiver}.${item.name}' }
}

fn (item ApiSymbol) url() string {
	prefix := if item.module_name == 'valibro' { '' } else { item.module_name + '--' }
	suffix := if item.kind in ['function', 'method'] { '' } else { '-type' }
	return '/api/${prefix}${reference_slug(item.label())}${suffix}/'
}

fn read_inventory(root string) ![]ApiSymbol {
	return json2.decode[[]ApiSymbol](os.read_file(os.join_path(root, 'site/reference.json'))!)!
}

fn extract_inventory(root string, out string) ![]ApiSymbol {
	mut symbols := []ApiSymbol{}
	for module_name in api_modules {
		folder := if module_name == 'valibro' { root } else { os.join_path(root, module_name) }
		command := '${os.quoted_path(@VEXE)} doc -f json -no-timestamp -o ${os.quoted_path(out)} ${os.quoted_path(folder)}'
		result := os.execute(command)
		if result.exit_code != 0 { return error(result.output) }
		document := json2.decode[map[string]json2.Any](os.read_file(os.join_path(out,
			'${module_name}.json'))!)!
		contents := document['contents'] or {
			return error('Missing v doc contents for ${module_name}')
		}
		collect_symbols(root, module_name, '', contents.as_array(), mut symbols)!
	}
	symbols.sort(a.id() < b.id())
	mut ids := map[string]bool{}
	mut urls := map[string]bool{}
	for symbol in symbols {
		if symbol.id() in ids { return error('Duplicate public API identity: ${symbol.id()}') }
		if symbol.url() in urls { return error('Duplicate public API URL: ${symbol.url()}') }
		ids[symbol.id()] = true
		urls[symbol.url()] = true
	}
	return symbols
}

fn collect_symbols(root string, module_name string, parent string, nodes []json2.Any, mut symbols []ApiSymbol) ! {
	for node in nodes {
		entry := node.as_map()
		raw_name := (entry['name'] or { continue }).str()
		raw_kind := (entry['kind'] or { json2.Any('') }).str()
		declaration := (entry['content'] or { json2.Any('') }).str()
		kind := if raw_kind == 'const_group' { 'const' } else { raw_kind }
		name := if raw_kind == 'const_group' && declaration.starts_with('const ') {
			declaration.fields()[1]
		} else {
			raw_name
		}
		public := (entry['public'] or { json2.Any(false) }).bool()
		if public && kind != '' {
			mut comments := []string{}
			for comment in (entry['comments'] or { json2.Any([]json2.Any{}) }).as_array() {
				text :=
					(comment.as_map()['text'] or { json2.Any('') }).str().trim_left('\x01').trim_space()
				if text != '' { comments << text }
			}
			path := (entry['file_path'] or { json2.Any('') }).str()
			absolute := os.real_path(path)
			prefix := os.real_path(root) + os.path_separator
			if !absolute.starts_with(prefix) { return error('Declaration outside package: ${path}') }
			file := absolute[prefix.len..].replace(os.path_separator, '/')
			position := (entry['pos'] or { json2.Any(map[string]json2.Any{}) }).as_map()
			symbols << ApiSymbol{
				module_name: module_name
				name:        name
				receiver:    if raw_kind == 'const_group' { '' } else { parent }
				kind:        kind
				declaration: declaration
				comment:     comments.join('\n')
				file:        file
				line:        (position['line_nr'] or { json2.Any(0) }).int() + 1
			}
		}
		// Generic receiver containers can be private synthetic DocNodes even
		// though their children are public. Always traverse those children.
		children := entry['children'] or { json2.Any([]json2.Any{}) }
		collect_symbols(root, module_name, name, children.as_array(), mut symbols)!
	}
}

fn update_inventory(root string) ! {
	folder := os.join_path(root, 'site/.inventory')
	if os.exists(folder) { return error('${folder} already exists') }
	os.mkdir_all(folder)!
	defer { os.rmdir_all(folder) or {} }
	symbols := extract_inventory(root, folder)!
	encoded := json2.encode(symbols, prettify: true)
	os.write_file(os.join_path(root, 'site/reference.json'), encoded + '\n')!
	println('Updated source inventory: ${symbols.len} public declarations in ${api_modules.len} modules')
}

fn reference_slug(label string) string {
	mut result := ''
	for c in label.to_lower().bytes() {
		if c.is_letter() || c.is_digit() || c == `_` {
			result += c.ascii_str()
		} else if c == `.` || c == `-` {
			result += '-'
		}
	}
	return result.trim('-')
}
