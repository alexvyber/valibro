module main

import os
import net.http

fn test_handbook_is_used_across_the_site() {
	pages := load_pages(@VMODROOT)!
	for url in ['/', '/api/', '/api/string/', '/guides/json-config/'] {
		html := render_page(handbook_page(pages, url), pages)
		assert html.contains('/assets/site.css')
		assert !html.contains('/assets/handbook.css')
		assert html.contains('class="handbook"')
	}
	pipe := render_page(handbook_page(pages, '/api/pipe/'), pages)
	assert pipe.contains('/assets/site.css')
	assert !pipe.contains('/assets/handbook.css')
	assert pipe.contains('class="handbook" data-theme="system"')
	assert pipe.contains('class="section-number">04</span>Execution')
	assert pipe.contains('<span>Output</span>')
	assert pipe.contains('&#39;alex_7&#39;')
	assert !pipe.contains('<script')
}

fn test_handbook_theme_preview_and_local_fonts() {
	mut app := App{
		pages:  load_pages(@VMODROOT)!
		assets: site_assets(@VMODROOT)!
	}
	for theme in ['light', 'dark'] {
		for path in ['/', '/api/', '/api/pipe/', '/api/types--schema-type/', '/guides/json-config/',
			'/search/'] {
			res := app.handle(http.Request{ url: '${path}?theme=${theme}' })
			assert res.status_code == 200
			assert res.body.contains('data-theme="${theme}"')
		}
	}
	assert app.handle(http.Request{ url: '/api/pipe/?theme=%3Cscript%3E' }).body.contains('data-theme="system"')
	for file in site_asset_files {
		res := app.handle(http.Request{ url: '/assets/${file}' })
		assert res.status_code == 200
		if file.ends_with('.woff2') {
			assert res.body.starts_with('wOF2')
			assert (res.header.get(.content_type) or { panic(err) }) == 'font/woff2'
		}
	}
	assert app.handle(http.Request{ url: '/assets/fonts/missing.woff2' }).status_code == 404
}

fn test_handbook_static_assets_are_exported() {
	folder := os.join_path(os.temp_dir(), 'valibro-handbook-test-${os.getpid()}')
	os.mkdir(folder)!
	defer { os.rmdir_all(folder) or {} }
	pages := load_pages(@VMODROOT)!
	build_site(@VMODROOT, folder, pages)!
	for file in site_asset_files {
		assert os.read_file(os.join_path(folder, 'assets', file))! == os.read_file(os.join_path(@VMODROOT,
			'site/assets', file))!
	}
	assert os.read_file(os.join_path(folder, 'api/pipe/index.html'))!.contains('/assets/site.css')
	assert os.read_file(os.join_path(folder, 'index.html'))!.contains('/assets/site.css')
}

fn handbook_page(pages []Page, url string) Page {
	for page in pages {
		if page.url == url { return page }
	}
	panic('Page not found: ${url}')
}

fn test_explicit_theme_links_keep_fragments_and_search_queries() {
	assert themed_url('/api/#execution', 'dark') == '/api/?theme=dark#execution'
	assert themed_url('/search/?q=pipe', 'light') == '/search/?q=pipe&theme=light'
	html := themed_links('<a href="/api/#execution">API</a><a href="#example">Example</a><a href="/api/pipe.md">Markdown</a>',
		'dark')
	assert html.contains('href="/api/?theme=dark#execution"')
	assert html.contains('href="#example"')
	assert html.contains('href="/api/pipe.md"')
}

fn test_search_keeps_theme_in_form_and_theme_controls() {
	mut app := App{
		pages: load_pages(@VMODROOT)!
	}
	res := app.handle(http.Request{ url: '/search/?q=pipe&theme=dark' })
	assert res.body.contains('data-theme="dark"')
	assert res.body.contains('name="theme" value="dark"')
	assert res.body.contains('/search/?q=pipe&amp;theme=light')
	assert res.body.contains('action="/search/"')
}
