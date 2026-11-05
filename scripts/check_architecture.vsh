#!/usr/bin/env -S v run

// Enforce module ownership without importing the package or building native engines.
import os

fn visit_module(name string, graph map[string][]string, mut marks map[string]int) {
	if marks[name] == 2 { return }
	assert marks[name] != 1, 'Circular package dependency through ${name}'
	marks[name] = 1
	for dependency in graph[name] {
		visit_module(dependency, graph, mut marks)
	}
	marks[name] = 2
}

root := @VMODROOT
allowed := {
	'valibro':   ['actions', 'schemas', 'methods', 'types', 'storages', 'jsoncodec', 'unicode']
	'types':     []string{}
	'internal':  ['internal', 'types', 'unicode']
	'methods':   ['types', 'internal']
	'schemas':   ['types', 'internal']
	'actions':   ['types', 'internal', 'schemas', 'methods', 'unicode', 'jsoncodec']
	'json':      ['types', 'internal', 'schemas', 'methods']
	'jsoncodec': ['types', 'internal']
	'storages':  ['types']
	'unicode':   []string{}
}
mut graph := map[string][]string{}
mut count := 0
for file in os.walk_ext(root, '.v') {
	relative := file[root.len + 1..].replace(os.path_separator, '/')
	parts := relative.split('/')
	layer := if parts.len == 1 { 'valibro' } else { parts[0] }
	if layer !in allowed { continue
	 }
	module_name := if parts.len == 1 {
		'valibro'
	} else {
		'valibro.' + parts[..parts.len - 1].join('.')
	}
	for raw in (os.read_file(file) or { panic(err) }).split_into_lines() {
		line := raw.trim_space()
		if !line.starts_with('import valibro') { continue
		 }
		dependency := line.fields()[1]
		dependency_layer := if dependency == 'valibro' {
			'valibro'
		} else {
			dependency.split('.')[1]
		}
		assert dependency_layer in allowed[layer], '${relative}: ${layer} must not depend on ${dependency}'
		mut dependencies := graph[module_name]
		if dependency !in dependencies { dependencies << dependency }
		graph[module_name] = dependencies
	}
	count++
}
mut marks := map[string]int{}
for name in graph.keys() {
	visit_module(name, graph, mut marks)
}
println('Architecture check passed: ${count} V source files, dependency boundaries and acyclic modules')
