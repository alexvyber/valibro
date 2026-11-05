module main

import os

struct Page {
	url         string
	title       string
	section     string
	file        string
	summary     string
	symbol      string
	api_id      string
	module_name string
	category    string
	api_kind    string
	source      string
	document    Markdown
}

fn load_pages(root string) ![]Page {
	mut definitions := [
		Page{
			url:      '/'
			title:    'Introduction'
			section:  'Guides'
			file:     'docs/guides/introduction.md'
			summary:  'Composable validation, written for V.'
			category: 'Getting started'
		},
		Page{
			url:      '/guides/quick-start/'
			title:    'Quick start'
			section:  'Guides'
			file:     'docs/guides/quick-start.md'
			summary:  'Build a schema, transform input, and handle validation issues.'
			category: 'Getting started'
		},
		Page{
			url:     '/api/string/'
			title:   'string'
			section: 'Schemas'
			file:    'docs/api/string.md'
			summary: 'Validate a native UTF-8 string.'
			symbol:  'string'
		},
		Page{
			url:     '/api/pipe/'
			title:   'pipe'
			section: 'Methods'
			file:    'docs/api/pipe.md'
			summary: 'Compose validations and transformations in order.'
			symbol:  'pipe'
		},
		Page{
			url:     '/api/parse/'
			title:   'parse'
			section: 'Methods'
			file:    'docs/api/parse.md'
			summary: 'Validate input and return a native V result.'
			symbol:  'parse'
		},
	]
	for guide in api_guides() {
		definitions << Page{
			url:      '/guides/${guide.slug}/'
			title:    guide.title
			section:  'Guides'
			file:     'docs/guides/${guide.slug}.md'
			summary:  guide.summary
			category: guide_category(guide.slug)
		}
	}
	inventory := read_inventory(root)!
	mut pages := []Page{}
	for definition in definitions {
		source := os.read_file(os.join_path(root, definition.file))!
		document := markdown(source)!
		if document.headings.len == 0 || document.headings[0].text != definition.title {
			return error('${definition.file}: first heading must match the page title')
		}
		pages << Page{
			...definition
			source:   source
			document: document
		}
	}
	authored_pages := pages.clone()
	extra := extra_example_programs(root)!
	for module_name in api_modules {
		pages << module_page(module_name, inventory)!
	}
	for item in inventory {
		mut matched_authored := false
		for i, page in pages {
			if page.url == item.url() {
				if page.symbol != item.name || item.module_name != 'valibro' {
					return error('Reference route collision: ${item.url()}')
				}
				pages[i] = Page{
					...page
					api_id:      item.id()
					module_name: item.module_name
					category:    api_category(item, inventory)
					api_kind:    item.kind
				}
				matched_authored = true
				break
			}
		}
		if !matched_authored { pages << reference_page(item, inventory, authored_pages, extra)! }
	}
	return pages
}

fn render_page(page Page, pages []Page, themes ...string) string {
	return render_shell(page, pages, page.document.html, page_theme(themes))
}

fn render_message(title string, body string, pages []Page, settings ...string) string {
	theme := page_theme(settings)
	url := if settings.len > 1 { settings[1] } else { '/search/' }
	page := Page{
		url:      url
		title:    title
		summary:  title
		category: 'Tools'
		section:  'Utility'
	}
	return render_shell(page, pages, '<h1>${escape(title)}</h1>${body}', theme)
}

fn search_html(pages []Page, query string, themes ...string) string {
	mut html := '<form class="search-page" action="/search/" method="get"><label for="query">Search the documentation</label><div><input id="query" name="q" type="search" value="${escape(query)}" maxlength="200"><button type="submit">Search</button></div></form>'
	theme := page_theme(themes)
	if theme != 'system' {
		html = html.replace('method="get">',
			'method="get"><input type="hidden" name="theme" value="${theme}">')
	}
	if query == '' { return html + '<p>Search for a function, concept, or example.</p>' }
	words := query.to_lower().fields()
	mut matches := []SearchHit{}
	for page in pages {
		haystack := (page.title + ' ' + page.summary + ' ' + page.source).to_lower()
		mut found := true
		for word in words {
			if !haystack.contains(word) {
				found = false
				break
			}
		}
		if !found { continue
		 }
		title := page.title.to_lower()
		needle := query.to_lower()
		score := if title == needle {
			100
		} else if title.starts_with(needle) {
			60
		} else if title.contains(needle) {
			40
		} else {
			10
		}
		matches << SearchHit{
			page:  page
			score: score + if page.module_name == 'valibro' { 5 } else { 0 }
		}
	}
	matches.sort(a.score > b.score)
	if matches.len > 0 { html += '<p>${matches.len} matching pages. Showing up to 50 results.</p>' }
	html += '<ul class="results">'
	for index, hit in matches {
		if index >= 50 { break
		 }
		page := hit.page
		html += '<li><a href="${page.url}">${escape(page.title)}</a><p class="result-context">${escape(if page.module_name != '' {
			page.module_name
		} else {
			page.category
		})}</p><p>${inline(page.summary) or { escape(page.summary) }}</p></li>'
	}
	html += '</ul>'
	if matches.len == 0 {
		html += '<p>No pages match “${escape(query)}”. Try a function name such as <code>pipe</code>.</p>'
	}

	return html
}

fn markdown_url(page Page) string {
	return if page.url == '/' { '/index.md' } else { page.url.trim_right('/') + '.md' }
}

struct SearchHit {
	page  Page
	score int
}
