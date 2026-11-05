module main

fn presented_page(pages []Page, url string) Page {
	for page in pages {
		if page.url == url { return page }
	}
	panic('Page not found: ${url}')
}

fn test_representative_pages_share_the_new_shell() {
	pages := load_pages(@VMODROOT)!
	for url in ['/', '/api/', '/api/pipe/', '/guides/json-config/'] {
		page := presented_page(pages, url)
		html := render_page(page, pages)
		assert html.contains('class="header-grid"')
		assert html.contains('aria-label="Breadcrumb"')
		assert html.contains('class="doc-article ')
		assert html.contains('class="mobile-nav"')
		assert html.contains('class="mobile-toc"')
		assert !html.contains('local-badge')
		assert !html.contains('class="mark"')
		assert !html.contains('Current reference')
		assert !html.contains('<script')
	}
	intro := render_page(pages[0], pages)
	assert intro.contains('class="intro-actions"')
	assert intro.contains('Browse the API')
}

fn test_api_navigation_opens_the_active_category() {
	pages := load_pages(@VMODROOT)!
	pipe := presented_page(pages, '/api/pipe/')
	assert pipe.category == 'Execution'
	html := documentation_navigation(pages, pipe.url)
	assert html.contains('<details class="book-section" open><summary><span class="section-number">04</span>Execution</summary>')
	assert html.contains('href="/api/pipe/" class="nav-symbol" aria-current="page"')
	assert html.contains('href="/api/#execution"')
	assert documentation_navigation(pages, '/api/json--strict_object/').contains('module-navigation" open')
}

fn test_api_indexes_render_complete_compact_rows() {
	pages := load_pages(@VMODROOT)!
	inventory := read_inventory(@VMODROOT)!
	for name in api_modules {
		page := presented_page(pages, module_url(name))
		members := inventory.filter(it.module_name == name)
		assert page.document.html.count('class="api-row"') == members.len
		for item in members {
			assert page.document.html.contains('class="api-row" href="${item.url()}"')
		}
	}
	root := presented_page(pages, '/api/')
	for group in navigation_groups() {
		assert root.document.html.contains('id="${heading_id(group.name)}"')
	}
}

fn test_rendered_navigation_and_contents_links_resolve() {
	pages := load_pages(@VMODROOT)!
	for url in ['/', '/api/', '/api/pipe/', '/guides/json-config/'] {
		html := render_page(presented_page(pages, url), pages)
		mut rest := html
		for rest.contains('href="') {
			rest = rest.all_after('href="')
			link := rest.all_before('"')
			if link.starts_with('https://') || link.starts_with('/assets/') { continue
			 }
			path := if link.starts_with('#') { url } else { link.all_before('#').all_before('?') }
			anchor := if link.contains('#') { link.all_after('#') } else { '' }
			mut valid := path == '/search/' && anchor == ''
			for target in pages {
				if markdown_url(target) == path && anchor == '' { valid = true }
				if target.url == path {
					valid = anchor == '' || anchor == 'main'
						|| target.document.headings.any(it.id == anchor)
				}
			}
			assert valid, '${url}: ${link}'
		}
	}
}

fn test_code_labels_and_mobile_notes_preserve_examples() {
	doc :=
		markdown('# Example\n\n> Native behavior: [Read more](/guides/native-behavior/).\n\n```v signature\nfn sample() string\n```\n\n```v\nassert true\n```')!
	assert doc.html.contains('<figcaption>Signature</figcaption>')
	assert doc.html.contains('<figcaption>V</figcaption>')
	assert doc.html.contains('<pre tabindex="0">')
	assert doc.html.contains('<aside class="note">')
	assert doc.examples == ['assert true\n']
	assert '/guides/native-behavior/' in doc.links
}
