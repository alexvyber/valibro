module main

import os
import net.http
import net.urllib

struct App {
	pages  []Page
	assets map[string]string
}

fn response(status http.Status, mime string, body string) http.Response {
	return http.new_response(
		status: status
		body:   body
		header: http.new_header(
			key:   .content_type
			value: mime
		)
	)
}

fn (mut app App) handle(request http.Request) http.Response {
	if request.method !in [.get, .head] {
		return response(.method_not_allowed, 'text/plain; charset=utf-8', 'Use GET or HEAD')
	}
	url := urllib.parse(request.url) or {
		return response(.bad_request, 'text/plain; charset=utf-8', 'Invalid URL')
	}
	path := url.path
	if asset := app.assets[path] {
		mime := if path.ends_with('.woff2') {
			'font/woff2'
		} else if path.ends_with('.css') {
			'text/css; charset=utf-8'
		} else if path.ends_with('.json') {
			'application/json'
		} else {
			'text/plain; charset=utf-8'
		}
		return response(.ok, mime, asset)
	}
	query := urllib.parse_query(url.raw_query) or {
		return response(.bad_request, 'text/plain', 'Invalid query')
	}
	theme := query.get('theme') or { 'system' }
	if path == '/search/' {
		search := query.get('q') or { '' }
		return response(.ok, 'text/html; charset=utf-8', render_message('Search', search_html(app.pages,
			search, theme), app.pages, theme, '/search/?q=' + urllib.query_escape(search)))
	}
	for page in app.pages {
		if path == page.url {
			return response(.ok, 'text/html; charset=utf-8', render_page(page, app.pages, theme))
		}
		if path == markdown_url(page) {
			return response(.ok, 'text/markdown; charset=utf-8', page.source)
		}
	}
	return response(.not_found, 'text/html; charset=utf-8', render_message('Page not found',
		'<p>Choose a page from the navigation.</p>', app.pages, theme, path))
}

fn main() {
	root := @VMODROOT
	command := if os.args.len > 1 { os.args[1] } else { 'serve' }
	if command == 'inventory' {
		update_inventory(root) or {
			eprintln(err)
			exit(1)
		}
		return
	}
	if command == 'audit' {
		mut missing := []string{}
		for item in read_inventory(root) or { panic(err) } {
			if symbol_summary(item) == '' { missing << item.id() }
		}
		if missing.len > 0 {
			eprintln(missing.join('\n'))
			exit(1)
		}
		println('All public declarations have semantic descriptions')
		return
	}
	pages := load_pages(root) or {
		eprintln(err)
		exit(1)
	}

	match command {
		'build' {
			out := if os.args.len > 2 { os.args[2] } else { os.join_path(root, 'site', 'public') }
			build_site(root, out, pages) or {
				eprintln(err)
				exit(1)
			}
			println('Built ${pages.len} pages in ${out}')
		}
		'check' {
			check_site(root, pages) or {
				eprintln(err)
				exit(1)
			}
		}
		'serve' {
			port := if os.args.len > 2 { os.args[2].int() } else { 8080 }
			if port < 1 || port > 65535 {
				eprintln('Port must be between 1 and 65535')
				exit(1)
			}
			mut server := http.Server{
				addr:       '127.0.0.1:${port}'
				handler:    App{
					pages:  pages
					assets: site_assets(root) or { panic(err) }
				}
				worker_num: 4
			}
			server.listen_and_serve()
		}
		else {
			eprintln('Usage: v run site [serve [port] | build [directory] | check | inventory | audit]')
			exit(1)
		}
	}
}
