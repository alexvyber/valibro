module main

import os

fn test_complete_public_reference_and_examples() {
	inventory := read_inventory(@VMODROOT)!
	pages := load_pages(@VMODROOT)!
	check_api_coverage(pages, inventory)!
	check_links(pages)!
	assert pages.filter(it.api_id != '').len == inventory.len
	for name in api_modules {
		assert inventory.any(it.module_name == name)
		index := pages.filter(it.url == module_url(name))[0]
		for item in inventory.filter(it.module_name == name) {
			assert index.document.links.contains(item.url()), item.id()
		}
	}
}

fn test_reference_includes_generic_receiver_methods_and_constants() {
	inventory := read_inventory(@VMODROOT)!
	assert inventory.any(it.module_name == 'types' && it.receiver == 'Set[T]' && it.name == 'count')
	assert inventory.any(it.module_name == 'types' && it.receiver == 'EntryMap[K, V]'
		&& it.name == 'count')
	assert inventory.any(it.module_name == 'methods' && it.receiver == 'CachedSchema[I, O]'
		&& it.name == 'clear')
	assert inventory.any(it.module_name == 'unicode' && it.name == 'version' && it.kind == 'const')
	mut urls := map[string]bool{}
	for item in inventory {
		assert !os.is_abs_path(item.file)
		assert !item.file.starts_with('internal/')
		assert os.is_file(os.join_path(@VMODROOT, item.file))
		assert item.name != ''
		assert item.line > 0
		// Static output also has to work on case-insensitive filesystems.
		url := item.url().to_lower()
		assert url !in urls, url
		urls[url] = true
	}
	assert inventory.filter(it.module_name == 'valibro' && it.name == 'parse')[0].url() == '/api/parse/'
}

fn test_api_coverage_rejects_missing_and_stale_reference() {
	inventory := read_inventory(@VMODROOT)!
	pages := load_pages(@VMODROOT)!
	missing := pages.filter(it.url != '/api/number/')
	if _ := check_api_coverage(missing, inventory) { assert false
	 }
	mut stale := pages.clone()
	for i, page in stale {
		if page.url == '/api/number/' { stale[i] = Page{
				...page
				source: '# number\n\nStale declaration'
			} }
	}
	if _ := check_api_coverage(stale, inventory) { assert false
	 }
}

fn test_inline_code_is_not_a_link_and_multiple_links_are_checked() {
	doc :=
		markdown('# Test\n\nUse `number_of[T]()` and [one](/api/number/) or [two](/api/number_of/).')!
	assert doc.links == ['/api/number/', '/api/number_of/']
	assert doc.html.contains('<code>number_of[T]()</code>')
}

fn test_search_ranks_exact_root_api_above_signature_mentions() {
	pages := load_pages(@VMODROOT)!
	results := search_html(pages, 'parse').all_after('<ul class="results">')
	assert results.starts_with('<li><a href="/api/parse/">parse</a>')
	assert results.count('<li>') <= 50
}
