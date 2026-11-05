module main

import os

const site_asset_files = ['site.css', 'fonts/IBMPlexSans-Regular.woff2',
	'fonts/IBMPlexSans-SemiBold.woff2', 'fonts/IBMPlexMono-Regular.woff2',
	'fonts/IBMPlexMono-Medium.woff2', 'fonts/LICENSE.txt', 'fonts/SOURCES.json']

fn site_assets(root string) !map[string]string {
	mut assets := map[string]string{}
	for file in site_asset_files {
		assets['/assets/${file}'] = os.read_file(os.join_path(root, 'site/assets', file))!
	}
	return assets
}

fn page_theme(themes []string) string {
	if themes.len > 0 && themes[0] in ['light', 'dark'] { return themes[0] }
	return 'system'
}

fn themed_url(url string, theme string) string {
	path := url.all_before('#')
	fragment := if url.contains('#') { '#' + url.all_after('#') } else { '' }
	separator := if path.contains('?') { '&' } else { '?' }
	return path + separator + 'theme=' + theme + fragment
}

// Carry an explicit theme through native links, without browser scripts or cookies.
fn themed_links(html string, theme string) string {
	if theme == 'system' { return html }
	mut rest := html
	mut out := ''
	for rest.contains('href="') {
		prefix := rest.all_before('href="') + 'href="'
		rest = rest.all_after('href="')
		href := rest.all_before('"')
		if href.starts_with('/') && !href.starts_with('/assets/')
			&& !href.all_before('#').ends_with('.md') && !href.contains('theme=') {
			out += prefix + escape(themed_url(href.replace('&amp;', '&'), theme))
		} else {
			out += prefix + href
		}
		out += '"'
		rest = rest.all_after('"')
	}
	return out + rest
}

fn render_shell(page Page, pages []Page, document string, selected_theme string) string {
	theme := page_theme([selected_theme])
	title := page.title
	description := page.summary
	mut body := document
	mut lead := ''
	if end := body.index('</h1>') { body = body[end + 5..] }
	if body.starts_with('<p>') {
		if end := body.index('</p>') {
			lead = body[3..end]
			body = body[end + 4..]
		}
	}
	body = body.replace('<figcaption>V</figcaption>',
		'<figcaption><span>Example</span><span>V</span></figcaption>')
	// Preserve the approved pipe example's output. Other pages keep their own
	// documented examples rather than inventing a generic output for every API.
	if page.url == '/api/pipe/' {
		if example := body.index('id="example"') {
			if end := body[example..].index('</figure>') {
				position := example + end + '</figure>'.len
				body = body[..position] +
					'<figure class="code-block output-block"><figcaption><span>Output</span><span>string</span></figcaption><pre tabindex="0"><code>${highlight_v("'alex_7'")}</code></pre></figure>' +
					body[position..]
			}
		}
	}
	if page.url == '/' {
		body =
			'<div class="intro-actions"><a href="/guides/quick-start/">Quick start →</a><a href="/api/">Browse the API →</a></div>' +
			body
	}
	page_class := if page.api_id != '' {
		'api-page'
	} else if page.section == 'Modules' {
		'index-page'
	} else if page.section == 'Utility' {
		'utility-page'
	} else {
		'guide-page'
	}
	title_class := if page.title.len > 24 { ' long-title' } else { '' }
	role := if page.api_id != '' {
		match page.api_kind {
			'function' { 'Function reference' }
			'method' { 'Method reference' }
			'typedef' { 'Type alias' }
			'struct' { 'Struct' }
			'interface' { 'Interface' }
			'enum' { 'Enum' }
			'const' { 'Constant' }
			else { 'API reference' }
		}
	} else if page.section == 'Modules' {
		'API index'
	} else if page.section == 'Utility' {
		'Documentation'
	} else {
		'Guide'
	}
	context := if page.module_name != '' {
		if page.module_name == 'valibro' { 'valibro' } else { 'valibro.' + page.module_name }
	} else {
		page.category
	}
	header_id := if page.document.headings.len > 0 {
		page.document.headings[0].id
	} else {
		heading_id(page.title)
	}
	contract := if page.url == '/api/pipe/' {
		'<div class="type-contract"><code>Schema[I, O]</code><span aria-hidden="true">→</span><code>Schema[I, O]</code><span class="contract-note">Same output type</span></div>'
	} else {
		''
	}
	nav := themed_links(documentation_navigation(pages, page.url), theme)
	toc := if page.section == 'Utility' { '' } else { table_of_contents(page) }
	mobile_toc := if toc == '' {
		''
	} else {
		'<details class="mobile-toc"><summary>On this page</summary><nav aria-label="Mobile page contents">${toc}</nav></details>'
	}
	margin_note := if page.url == '/api/pipe/' {
		'<p class="margin-note">A pipeline keeps its output type. For a type-changing step, use <a href="/api/pipe_to/">pipe_to</a>.</p>'
	} else {
		''
	}
	toc_panel := if toc == '' {
		''
	} else {
		'<aside class="page-toc"><nav aria-label="On this page">${toc}</nav>${themed_links(margin_note,
			theme)}</aside>'
	}
	pager := if page.section == 'Utility' {
		''
	} else {
		themed_links(adjacent_navigation(page, pages), theme)
	}
	crumbs := themed_links(breadcrumb(page), theme)
	light_url := escape(themed_url(page.url, 'light'))
	dark_url := escape(themed_url(page.url, 'dark'))
	guides_active := if page.url == '/' || page.url.starts_with('/guides/') {
		' aria-current="page"'
	} else {
		''
	}
	api_active := if page.url.starts_with('/api/') { ' aria-current="page"' } else { '' }
	home_url := escape(if theme == 'system' { '/' } else { themed_url('/', theme) })
	api_url := escape(if theme == 'system' { '/api/' } else { themed_url('/api/', theme) })
	search_url := escape(if theme == 'system' { '/search/' } else { themed_url('/search/', theme) })
	source_url := if page.section == 'Utility' { home_url } else { markdown_url(page) }
	source_label := if page.section == 'Utility' { 'Documentation' } else { 'Read Markdown ↗' }
	body = themed_links(body, theme)
	return $tmpl('templates/layout.html')
}
