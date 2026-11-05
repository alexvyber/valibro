module main

import strings

struct Heading {
	id    string
	text  string
	level int
}

struct Markdown {
	html     string
	headings []Heading
	links    []string
	examples []string
}

fn escape(value string) string {
	return value.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"',
		'&quot;').replace("'", '&#39;')
}

fn heading_id(text string) string {
	mut id := ''
	for c in text.to_lower().bytes() {
		if (c >= `a` && c <= `z`) || (c >= `0` && c <= `9`) {
			id += c.ascii_str()
		} else if c == ` ` || c == `-` || c == `_` {
			id += '-'
		}
	}
	return id.trim('-')
}

// Deliberately bounded: inline code and links, with raw HTML always escaped.
struct InlineContent {
	html  string
	links []string
}

fn inline(text string) !string {
	content := parse_inline(text)!
	return content.html
}

fn parse_inline(text string) !InlineContent {
	mut out := strings.new_builder(text.len)
	mut links := []string{}
	mut i := 0
	for i < text.len {
		if text[i] == `\`` {
			end := text[i + 1..].index('`') or { return error('Unclosed inline code: ${text}') }
			out.write_string('<code>${escape(text[i + 1..i + 1 + end])}</code>')
			i += end + 2
		} else if text[i] == `[` {
			if middle := text[i..].index('](') {
				start := i + middle + 2
				end := text[start..].index(')') or { return error('Unclosed link: ${text}') }
				href := text[start..start + end]
				if !(href.starts_with('/') || href.starts_with('#') || href.starts_with('https://'))
					|| href.starts_with('//') {
					return error('Unsupported link target: ${href}')
				}
				links << href
				out.write_string('<a href="${escape(href)}">${escape(text[i + 1..i + middle])}</a>')
				i = start + end + 1
			} else {
				out.write_string(escape(text[i..i + 1]))
				i++
			}
		} else {
			out.write_string(escape(text[i..i + 1]))
			i++
		}
	}
	return InlineContent{
		html:  out.str()
		links: links
	}
}

fn markdown(source string) !Markdown {
	mut out := strings.new_builder(source.len * 2)
	mut headings := []Heading{}
	mut ids := map[string]int{}
	mut examples := []string{}
	mut links := []string{}
	mut paragraph := []string{}
	mut list := false
	mut fenced := false
	mut language := ''
	mut code := []string{}
	for line in source.split_into_lines() {
		if line.starts_with('```') {
			if fenced {
				text := code.join('\n') + '\n'
				is_v := language in ['v', 'v signature']
				rendered := if is_v { highlight_v(text) } else { escape(text) }
				code_language := if is_v { 'v' } else { language }
				label := if language == 'v signature' {
					'Signature'
				} else if language == 'v' {
					'V'
				} else if language == 'sh' {
					'Terminal'
				} else {
					'Text'
				}
				block_class := if language == 'v signature' {
					'code-block signature-block'
				} else {
					'code-block'
				}
				out.write_string('<figure class="${block_class}"><figcaption>${label}</figcaption><pre tabindex="0"><code class="language-${escape(code_language)}">${rendered}</code></pre></figure>')
				if language == 'v' { examples << text }
				code.clear()
			} else {
				flush_paragraph(mut out, mut paragraph)!
				if list {
					out.write_string('</ul>')
					list = false
				}
				language = line[3..].trim_space()
				if language !in ['v', 'v signature', 'text', 'sh', ''] {
					return error('Unsupported code language: ${language}')
				}
			}
			fenced = !fenced
			continue
		}
		if fenced {
			code << line
			continue
		}
		parsed := parse_inline(line)!
		links << parsed.links
		if line.starts_with('> ') {
			flush_paragraph(mut out, mut paragraph)!
			if list {
				out.write_string('</ul>')
				list = false
			}
			out.write_string('<aside class="note">${inline(line[2..])!}</aside>')
			continue
		}
		if line.starts_with('- ') {
			flush_paragraph(mut out, mut paragraph)!
			if !list {
				out.write_string('<ul>')
				list = true
			}
			out.write_string('<li>${inline(line[2..])!}</li>')
			continue
		}
		if list {
			out.write_string('</ul>')
			list = false
		}
		if line.starts_with('#') {
			flush_paragraph(mut out, mut paragraph)!
			level := line.len - line.trim_left('#').len
			if level > 3 || !line.starts_with('#'.repeat(level) + ' ') {
				return error('Unsupported heading: ${line}')
			}
			text := line[level + 1..]
			base := heading_id(text)
			if base == '' { return error('Heading needs a readable anchor: ${text}') }
			ids[base]++
			id := if ids[base] == 1 { base } else { '${base}-${ids[base]}' }
			headings << Heading{
				id:    id
				text:  text
				level: level
			}
			out.write_string('<h${level} id="${id}">${inline(text)!}<a class="anchor" href="#${id}" aria-label="Link to ${escape(text)}">#</a></h${level}>')
		} else if line.trim_space() == '' {
			flush_paragraph(mut out, mut paragraph)!
		} else {
			paragraph << line.trim_space()
		}
	}
	if fenced { return error('Unclosed code fence') }
	flush_paragraph(mut out, mut paragraph)!
	if list { out.write_string('</ul>') }
	return Markdown{
		html:     out.str()
		headings: headings
		links:    links
		examples: examples
	}
}

fn flush_paragraph(mut out strings.Builder, mut paragraph []string) ! {
	if paragraph.len > 0 {
		out.write_string('<p>${inline(paragraph.join(' '))!}</p>')
		paragraph.clear()
	}
}
