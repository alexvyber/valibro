module methods

import valibro.types

pub struct FlatErrors {
pub:
	root   []string
	nested map[string][]string
	other  []string
}

pub fn get_dot_path(issue types.Issue) string {
	if issue.dot_path_unavailable { return '' }
	mut key := ''
	for part in issue.path {
		text := match part {
			int { part.str() }
			string { part }
		}

		key += if key == '' { text } else { '.' + text }
	}
	return key
}

pub fn flatten(issues []types.Issue) FlatErrors {
	mut root := []string{}
	mut nested := map[string][]string{}
	mut other := []string{}
	for issue in issues {
		if issue.path.len == 0 && !issue.path_present {
			root << issue.message
		} else {
			key := get_dot_path(issue)
			if key == '' {
				other << issue.message
			} else {
				nested[key] << issue.message
			}
		}
	}
	return FlatErrors{
		root:   root
		nested: nested
		other:  other
	}
}

pub fn summarize(issues []types.Issue) string {
	mut lines := []string{}
	for issue in issues {
		path := get_dot_path(issue)
		lines << '× ' + issue.message + if path == '' { '' } else { '\n  → at ' + path }
	}
	return lines.join('\n')
}
