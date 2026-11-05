module main

import os

fn build_site(root string, out string, pages []Page) ! {
	os.mkdir_all(out)!
	os.mkdir_all(os.join_path(out, 'assets'))!
	for asset in site_asset_files {
		target := os.join_path(out, 'assets', asset)
		os.mkdir_all(os.dir(target))!
		os.cp(os.join_path(root, 'site/assets', asset), target)!
	}
	mut index := '# Valibro documentation\n\n'
	for page in pages {
		folder := os.join_path(out, page.url.trim('/'))
		os.mkdir_all(folder)!
		os.write_file(os.join_path(folder, 'index.html'), render_page(page, pages))!
		md_path := if page.url == '/' {
			os.join_path(out, 'index.md')
		} else {
			os.join_path(out, page.url.trim('/') + '.md')
		}
		os.write_file(md_path, page.source)!
		index += '- [${page.title}](${if page.url == '/' {
			'/index.md'
		} else {
			page.url.trim_right('/') + '.md'
		}}): ${page.summary}\n'
	}
	os.write_file(os.join_path(out, 'llms.txt'), index)!
	os.mkdir_all(os.join_path(out, 'search'))!
	// A static export has no V search handler; provide a complete browsable index.
	mut listing := '<p>This static export includes a page index. Use your browser’s Find command to locate a topic.</p><ul class="results">'
	for page in pages {
		listing += '<li><a href="${page.url}">${escape(page.title)}</a><p>${escape(page.summary)}</p></li>'
	}
	listing += '</ul>'
	os.write_file(os.join_path(out, 'search/index.html'), render_message('Documentation index',
		listing, pages))!
	os.write_file(os.join_path(out, '404.html'), render_message('Page not found',
		'<p>Choose a page from the navigation.</p>', pages))!
}

fn check_links(pages []Page) ! {
	for page in pages {
		for link in page.document.links {
			if link.starts_with('https://') { continue
			 }
			path := if link.starts_with('#') { page.url } else { link.all_before('#') }
			anchor := if link.contains('#') { link.all_after('#') } else { '' }
			mut found := false
			for target in pages {
				if target.url != path { continue
				 }
				found = anchor == '' || target.document.headings.any(it.id == anchor)
			}
			if !found { return error('${page.file}: broken internal link ${link}') }
		}
	}
}

fn check_site(root string, pages []Page) ! {
	check_links(pages)!
	previous_reporting := os.getenv_opt('V_C_ERROR_BUG_REPORT_DISABLED')
	os.setenv('V_C_ERROR_BUG_REPORT_DISABLED', '1', true)
	defer {
		if previous := previous_reporting {
			os.setenv('V_C_ERROR_BUG_REPORT_DISABLED', previous, true)
		} else {
			os.unsetenv('V_C_ERROR_BUG_REPORT_DISABLED')
		}
	}
	// Use V's parser-backed documentation tool, rather than a second signature parser.
	temporary := os.join_path(root, 'site', '.checks-${os.getpid()}')
	if os.exists(temporary) {
		return error('${temporary} already exists; remove the previous check output first')
	}
	os.mkdir_all(temporary)!
	defer { os.rmdir_all(temporary) or {} }
	vexe := os.quoted_path(@VEXE)
	inventory := extract_inventory(root, os.join_path(temporary, 'api'))!
	if inventory != read_inventory(root)! {
		return error('Public API inventory is stale. Run: v run site inventory')
	}
	check_api_coverage(pages, inventory)!
	mut programs := []DocProgram{}
	mut placements := 0
	for page in pages {
		for example in page.document.examples {
			programs << DocProgram{
				label: page.file
				code:  example
			}
			placements++
		}
	}
	for index, example in extra_example_programs(root)! {
		programs << DocProgram{
			label: 'docs/examples program ${index}'
			code:  example.trim_right('\n') + '\n'
		}
	}
	mut unique := []DocProgram{}
	mut seen_examples := map[string]bool{}
	for program in programs {
		if program.code in seen_examples { continue
		 }
		seen_examples[program.code] = true
		unique << program
	}
	mut failures := []string{}
	// Generic-heavy V examples can use substantial compiler memory. Run one
	// compiler at a time; deduplication keeps repeated reference snippets cheap.
	for index, program in unique {
		failure := check_doc_program(vexe, temporary, index, program)
		if failure != '' { failures << failure }
	}
	count := unique.len
	if failures.len > 0 { return error(failures.join('\n\n')) }
	println('Docs check passed: ${pages.len} pages, ${inventory.len} source-checked public declarations, ${count} unique executable examples (${placements} placements), internal links and anchors')
}

fn check_api_coverage(pages []Page, inventory []ApiSymbol) ! {
	mut urls := map[string]bool{}
	mut documented := map[string]Page{}
	for page in pages {
		if page.url in urls { return error('Duplicate docs URL: ${page.url}') }
		urls[page.url] = true
		if page.api_id != '' {
			if page.api_id in documented { return error('Duplicate documented API: ${page.api_id}') }
			documented[page.api_id] = page
		}
	}
	if documented.len != inventory.len {
		return error('Public API coverage count differs from inventory')
	}
	for item in inventory {
		page := documented[item.id()] or { return error('Undocumented API: ${item.id()}') }
		if page.url != item.url() || !page.source.contains(item.declaration) {
			return error('Incorrect API declaration: ${item.id()}')
		}
		if page.document.examples.len == 0 {
			return error('Missing inline executable example: ${item.id()}')
		}
	}
}

struct DocProgram {
	label string
	code  string
}

fn check_doc_program(vexe string, temporary string, index int, program DocProgram) string {
	folder := os.join_path(temporary, 'example_${index}')
	os.mkdir_all(folder) or { return '${program.label}: ${err}' }
	file := os.join_path(folder, 'main.v')
	os.write_file(file, program.code) or { return '${program.label}: ${err}' }
	checked := os.execute('${vexe} -no-parallel run ${os.quoted_path(file)}')
	if checked.exit_code != 0 {
		return '${program.label}: example ${index} failed\n${checked.output}'
	}
	return ''
}
