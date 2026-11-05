module main

struct NavGroup {
	name  string
	slugs []string
}

fn navigation_groups() []NavGroup {
	return [
		NavGroup{'Schemas', ['schemas', 'objects', 'collections', 'presence']},
		NavGroup{'Validation', ['strings', 'numbers', 'custom']},
		NavGroup{'Transformations', ['transforms', 'unicode']},
		NavGroup{'Execution', ['execution', 'errors', 'configuration']},
		NavGroup{'JSON', ['json', 'json-config']},
		NavGroup{'Advanced', ['async', 'cache', 'metadata', 'types', 'native-behavior']},
	]
}

fn guide_category(slug string) string {
	for group in navigation_groups() {
		if slug in group.slugs { return group.name }
	}
	return 'Getting started'
}

fn nav_link(url string, label string, current string, monospace bool) string {
	active := if url == current { ' aria-current="page"' } else { '' }
	class := if monospace { ' class="nav-symbol"' } else { '' }
	return '<li><a href="${url}"${class}${active}>${escape(label)}</a></li>'
}

fn documentation_navigation(pages []Page, current string) string {
	mut html := '<p class="nav-caption">Documentation</p><ul class="start-links">'
	html += nav_link('/', 'Introduction', current, false)
	html += nav_link('/guides/quick-start/', 'Quick start', current, false)
	html += nav_link('/api/', 'API reference', current, false) + '</ul>'
	mut selected := Page{}
	for page in pages {
		if page.url == current {
			selected = page
			break
		}
	}
	for group_index, group in navigation_groups() {
		opened := if selected.category == group.name { ' open' } else { '' }
		html += '<details class="book-section"${opened}><summary><span class="section-number">0${
			group_index + 1}</span>${group.name}</summary><ul>'
		for slug in group.slugs {
			url := '/guides/${slug}/'
			for page in pages {
				if page.url == url { html += nav_link(url, page.title, current, false) }
			}
		}
		if selected.api_id != '' && selected.module_name == 'valibro'
			&& selected.category == group.name {
			mut members := pages.filter(it.api_id != '' && it.module_name == 'valibro'
				&& it.category == group.name)
			members.sort(a.title < b.title)
			for index, member in members {
				if member.url != current { continue
				 }
				start := if index > 2 { index - 2 } else { 0 }
				end := if index + 3 < members.len { index + 3 } else { members.len }
				html += '<li class="nav-break" aria-hidden="true"></li>'
				for nearby in members[start..end] {
					html += nav_link(nearby.url, nearby.title, current, true)
				}
			}
		}
		html += nav_link('/api/#${heading_id(group.name)}',
			'Browse ${group.name.to_lower()} APIs →', '', false)
		html += '</ul></details>'
	}
	opened := if selected.module_name != '' && selected.module_name != 'valibro' {
		' open'
	} else {
		''
	}
	html += '<details class="book-section module-navigation"${opened}><summary><span class="section-number">07</span>Modules</summary><ul>'
	for page in pages {
		if page.section == 'Modules' && page.module_name != 'valibro' {
			html += nav_link(page.url, page.title, current, true)
			if selected.api_id != '' && selected.module_name == page.module_name {
				html += nav_link(selected.url, selected.title, current, true)
			}
		}
	}
	return html + '</ul></details>'
}

fn breadcrumb(page Page) string {
	mut html := '<nav class="breadcrumbs" aria-label="Breadcrumb"><a href="/">Docs</a><span aria-hidden="true">/</span>'
	if page.api_id != '' || page.section == 'Modules' {
		html += '<a href="/api/">API reference</a>'
		if page.module_name == 'valibro' && page.api_id != '' {
			html += '<span aria-hidden="true">/</span><a href="/api/#${heading_id(page.category)}">${escape(page.category)}</a>'
		}
		if page.module_name != 'valibro' {
			html += '<span aria-hidden="true">/</span><a href="${module_url(page.module_name)}">${escape(page.module_name)}</a>'
		}
	} else {
		html += '<span>${escape(page.category)}</span>'
	}
	return html + '</nav>'
}

fn table_of_contents(page Page) string {
	mut html := '<p class="toc-heading">On this page</p><ul>'
	for heading in page.document.headings[1..] {
		class := if heading.level == 3 { ' class="toc-subheading"' } else { '' }
		html += '<li${class}><a href="#${heading.id}">${escape(heading.text)}</a></li>'
	}
	return html +
		'</ul><a class="source-link" href="${markdown_url(page)}">Read Markdown <span aria-hidden="true">↗</span></a>'
}

fn adjacent_navigation(page Page, pages []Page) string {
	// Move through the same learning path or module, rather than unrelated
	// neighbors in the combined inventory ordering.
	mut members := if page.api_id != '' {
		pages.filter(it.api_id != '' && it.module_name == page.module_name
			&& it.category == page.category)
	} else {
		pages.filter(it.api_id == '' && it.section == page.section)
	}
	if page.api_id != '' { members.sort(a.title < b.title) }
	mut html := '<nav class="pager" aria-label="Adjacent pages">'
	for index, member in members {
		if member.url != page.url { continue
		 }
		if index > 0 {
			html += '<a href="${members[index - 1].url}"><small>Previous</small><span>← ${escape(members[index - 1].title)}</span></a>'
		}
		if index + 1 < members.len {
			html += '<a class="pager-next" href="${members[index + 1].url}"><small>Next</small><span>${escape(members[
				index + 1].title)} →</span></a>'
		}
	}
	return html + '</nav>'
}

fn api_row(page Page) string {
	label := if page.module_name != '' && page.module_name != 'valibro' {
		'${page.module_name}.${page.title}'
	} else {
		page.title
	}
	return '<a class="api-row" href="${page.url}"><code>${escape(label)}</code><span class="row-description">${inline(page.summary) or {
		escape(page.summary)
	}}</span></a>'
}

fn api_category(item ApiSymbol, inventory []ApiSymbol) string {
	if item.kind !in ['function', 'method'] { return 'Advanced' }
	if item.module_name == 'valibro' {
		for other in inventory {
			if other.module_name in ['schemas', 'actions', 'methods'] && other.name == item.name
				&& other.receiver == '' {
				return api_category(other, inventory)
			}
		}
	}
	if item.module_name in ['json', 'jsoncodec'] { return 'JSON' }
	if item.module_name == 'schemas' { return 'Schemas' }
	if item.module_name == 'actions' {
		if item.file.contains('metadata') { return 'Advanced' }
		if item.file.contains('/json.') || item.name.starts_with('stringify_json') { return 'JSON' }
		if item.declaration.contains('Transformation[') || item.name.starts_with('to_')
			|| item.name.starts_with('trim') || item.name.starts_with('transform')
			|| item.name.starts_with('raw_transform') || item.name.starts_with('filter_')
			|| item.name.starts_with('sort_') || item.name.starts_with('readonly')
			|| item.name == 'normalize' {
			return 'Transformations'
		}
		return 'Validation'
	}
	return guide_category(symbol_guide(item, inventory))
}
