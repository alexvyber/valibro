module methods

import valibro.internal.diagnostics
import valibro.types

pub fn partial_check[I, O](schema types.Schema[I, O], paths [][]types.PathSegment, predicate fn (O) bool, messages ...types.ErrorMessage) types.Schema[I, O] {
	assert messages.len <= 1, 'Expected at most one custom message'
	text := if messages.len == 1 { messages[0] } else { types.ErrorMessage(types.DefaultMessage{
			text: 'Invalid input'
		}) }
	selected := paths.clone()
	return types.Schema[I, O]{
		...schema
		run: fn [schema, selected, predicate, text] [I, O](input I, config types.Config) types.Dataset[O] {
			result := types.run[I, O](schema, input, config)
			if result.exception != none { return result }
			if (config.abort_early || config.abort_pipe_early) && result.issues.len > 0 {
				return result
			}
			if !result.typed {
				for path in selected {
					for issue in result.issues {
						if paths_overlap(issue, path) { return result }
					}
				}
			}
			if predicate(result.value) { return result }
			mut issues := result.issues.clone()
			received := diagnostics.issue_value[O](result.value)
			display := 'Invalid input: Received ' + received
			message := if text is types.DefaultMessage { types.ErrorMessage(types.DefaultMessage{
					text: display
				}) } else { text }
			issues << types.new_issue('partial_check', message, '', received, display)
			return types.Dataset[O]{
				...result
				issues: issues
			}
		}
	}
}

fn paths_overlap(issue types.Issue, selected []types.PathSegment) bool {
	for i := 0; i < issue.path.len && i < selected.len; i++ {
		kind := if i < issue.path_types.len {
			issue.path_types[i]
		} else {
			'unknown'
		}
		wildcard := selected[i] == types.PathSegment('$') && kind == 'array'
		if issue.path[i] != selected[i] && !wildcard { return false }
	}
	return true
}
