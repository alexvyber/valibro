module main

import net.http
import os

fn test_markdown_escapes_html_and_code() {
	doc := markdown('# Title\n\n<script>alert(1)</script>\n\n```v\nassert 1 < 2\n```')!
	assert !doc.html.contains('<script>')
	assert doc.html.contains('&lt;script&gt;')
	assert doc.html.contains('<span class="hl-keyword">assert</span>')
	assert doc.html.contains('<span class="hl-operator">&lt;</span>')
	assert doc.examples == ['assert 1 < 2\n']
}

fn test_markdown_checks_fences_links_and_duplicate_anchors() {
	doc := markdown('# Title\n\n## Example\n\n## Example\n\n[Read](/api/pipe/#example)')!
	assert doc.headings[1].id == 'example'
	assert doc.headings[2].id == 'example-2'
	assert doc.links == ['/api/pipe/#example']
	if _ := markdown('```v\nunfinished') { assert false
	 }
	if _ := markdown('[bad](javascript:alert)') { assert false
	 }
	if _ := markdown('[bad](//example.com)') { assert false
	 }
}

fn test_site_navigation_and_search() {
	pages := load_pages(@VMODROOT)!
	check_links(pages)!
	html := render_page(pages[2], pages)
	assert html.contains('href="/api/string/" class="nav-symbol" aria-current="page"')
	assert html.contains('href="#signature"')
	assert html.contains('Skip to content')
	assert !html.contains('<script')
	assert search_html(pages, 'UTF-8').contains('href="/api/string/"')
	assert search_html(pages, 'absent-unfindable-word').contains('No pages match')
	assert !search_html(pages, '<script>').contains('<script>')
}

fn test_broken_anchor_is_rejected() {
	page := Page{
		url:      '/'
		file:     'test.md'
		document: markdown('# Test\n\n[Missing](#missing)')!
	}
	if _ := check_links([page]) { assert false
	 }
}

fn test_http_routes_and_search() {
	mut app := App{
		pages:  load_pages(@VMODROOT)!
		assets: {
			'/assets/site.css': 'body {}'
		}
	}
	for path in ['/', '/guides/quick-start/', '/api/string/', '/api/pipe/', '/api/parse/'] {
		res := app.handle(http.Request{ url: path })
		assert res.status_code == 200
		assert res.body.contains('<main id="main"')
	}
	assert app.handle(http.Request{ url: '/api/missing/' }).status_code == 404
	assert app.handle(http.Request{ url: '/api/string/', method: .post }).status_code == 405
	css := app.handle(http.Request{ url: '/assets/site.css' })
	assert css.body == 'body {}'
	assert (css.header.get(.content_type) or { panic(err) }) == 'text/css; charset=utf-8'
	raw := app.handle(http.Request{ url: '/api/string.md' })
	assert raw.body.starts_with('# string')
	assert (raw.header.get(.content_type) or { panic(err) }) == 'text/markdown; charset=utf-8'
	assert app.handle(http.Request{ url: '/search/?q=UTF-8' }).body.contains('href="/api/string/"')
	assert app.handle(http.Request{ url: '/search/' }).status_code == 200
}

fn test_static_export() {
	folder := os.join_path(os.temp_dir(), 'valibro-site-test-${os.getpid()}')
	os.mkdir(folder)!
	defer { os.rmdir_all(folder) or {} }
	pages := load_pages(@VMODROOT)!
	build_site(@VMODROOT, folder, pages)!
	for page in pages {
		html := os.read_file(os.join_path(folder, page.url.trim('/'), 'index.html'))!
		assert html.contains('<title>${page.title} · Valibro</title>')
		assert html.contains('class="handbook" data-theme="system"')
		assert html.contains('/assets/site.css')
		assert !html.contains('/assets/handbook.css')
		assert !html.contains('<script')
		assert os.read_file(os.join_path(folder, markdown_url(page).trim_left('/')))! == page.source
	}
	assert os.read_file(os.join_path(folder, 'search/index.html'))!.contains('Documentation index')
	assert os.read_file(os.join_path(folder, 'llms.txt'))!.contains('/api/parse.md')
	assert os.is_file(os.join_path(folder, 'assets/site.css'))
	assert os.is_file(os.join_path(folder, '404.html'))
}

fn test_rebuilding_export_removes_retired_api_routes_and_preserves_other_files() {
	folder := os.join_path(os.temp_dir(), 'valibro-retired-routes-${os.getpid()}')
	os.mkdir_all(folder)!
	defer { os.rmdir_all(folder) or {} }
	pages := load_pages(@VMODROOT)!
	retired := Page{
		url:      '/api/retired_example/'
		title:    'Retired example'
		source:   '# Retired example\n'
		document: markdown('# Retired example\n')!
	}
	mut previous := pages.clone()
	previous << retired
	build_site(@VMODROOT, folder, previous)!
	os.write_file(os.join_path(folder, 'api/retired_example/notes.txt'), 'Keep user files')!
	build_site(@VMODROOT, folder, pages)!
	assert !os.exists(os.join_path(folder, 'api/retired_example.md'))
	assert !os.exists(os.join_path(folder, 'api/retired_example/index.html'))
	assert os.read_file(os.join_path(folder, 'api/retired_example/notes.txt'))! == 'Keep user files'
	assert os.is_file(os.join_path(folder, 'api/parse/index.html'))
}
