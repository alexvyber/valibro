module schemas

import valibro.internal.comparison
import valibro.internal.diagnostics
import valibro.types

pub fn literal[T](requirement T, messages ...types.ErrorMessage) types.Schema[T, T] {
	text := schema_message(messages, 'Invalid literal')
	return types.Schema[T, T]{
		type_name: 'literal'
		expects:   diagnostics.issue_value(requirement)
		message:   text
		run:       fn [requirement, text] [T](input T, config types.Config) types.Dataset[T] {
			if comparison.value_equal(input, requirement) { return types.Dataset[T]{
					value: input
				} }
			return types.Dataset[T]{
				typed:  false
				value:  input
				issues: [
					types.schema_type_issue('literal', text, diagnostics.issue_value(requirement),
						diagnostics.issue_value(input), 'type'),
				]
			}
		}
	}
}

pub fn picklist[T](requirements []T, messages ...types.ErrorMessage) types.Schema[T, T] {
	items := requirements.clone()
	text := schema_message(messages, 'Invalid picklist value')
	return types.Schema[T, T]{
		type_name: 'picklist'
		expects:   diagnostics.joined_values(items)
		message:   text
		run:       fn [items, text] [T](input T, config types.Config) types.Dataset[T] {
			mut found := false
			for item in items {
				if comparison.value_equal(input, item) {
					found = true
					break
				}
			}
			if found { return types.Dataset[T]{
					value: input
				} }
			return types.Dataset[T]{
				typed:  false
				value:  input
				issues: [
					types.schema_type_issue('picklist', text, diagnostics.joined_values(items),
						diagnostics.issue_value(input), 'type'),
				]
			}
		}
	}
}

pub fn custom[T](predicate fn (T) bool, messages ...types.ErrorMessage) types.Schema[T, T] {
	text := schema_message(messages, 'Invalid input')
	return types.Schema[T, T]{
		type_name: 'custom'
		expects:   'unknown'
		message:   text
		run:       fn [predicate, text] [T](input T, config types.Config) types.Dataset[T] {
			if predicate(input) { return types.Dataset[T]{
					value: input
				} }
			return types.Dataset[T]{
				typed:  false
				value:  input
				issues: [
					types.schema_type_issue('custom', text, 'unknown',
						diagnostics.issue_value(input), 'type'),
				]
			}
		}
	}
}

pub fn never[T](messages ...types.ErrorMessage) types.Schema[T, T] {
	text := schema_message(messages, 'Expected never')
	return types.Schema[T, T]{
		type_name: 'never'
		expects:   'never'
		message:   text
		run:       fn [text] [T](input T, config types.Config) types.Dataset[T] {
			return types.Dataset[T]{
				typed:  false
				value:  input
				issues: [
					types.schema_type_issue('never', text, 'never', diagnostics.issue_value(input),
						'type'),
				]
			}
		}
	}
}

pub fn lazy[I, O](getter fn () types.Schema[I, O]) types.Schema[I, O] {
	return types.Schema[I, O]{
		type_name: 'lazy'
		expects:   'unknown'
		run:       fn [getter] [I, O](input I, config types.Config) types.Dataset[O] {
			return types.run[I, O](getter(), input, config)
		}
	}
}

pub fn union[I, O](options []types.Schema[I, O], messages ...types.ErrorMessage) types.Schema[I, O] {
	items := options.clone()
	text := schema_message(messages, 'Invalid union')
	expected := diagnostics.join_expects(items.map(it.expects))
	return types.Schema[I, O]{
		type_name: 'union'
		expects:   expected
		message:   text
		run:       fn [items, text, expected] [I, O](input I, config types.Config) types.Dataset[O] {
			mut typed := []types.Dataset[O]{}
			mut untyped := []types.Dataset[O]{}
			for item in items {
				result := types.run[I, O](item, input, config)
				if exception := result.exception { return types.Dataset[O]{
						typed:     false
						exception: exception
					} }
				if result.typed && result.issues.len == 0 { return result }
				if result.typed { typed << result } else { untyped << result }
			}
			candidates := if typed.len > 0 { typed } else { untyped }
			if candidates.len == 1 { return candidates[0] }
			mut issues := []types.Issue{}
			for candidate in candidates {
				issues << candidate.issues
			}
			mut value := O{}
			$if I is O { value = input }
			return types.Dataset[O]{
				// Multiple failing candidates do not select any branch output.
				raw_value: types.value_of[I](input)
				value:     value
				typed:     typed.len > 0
				issues:    [
					types.Issue{
						...types.schema_type_issue('union', text, expected,
							diagnostics.issue_value(input), 'type')
						issues: issues
					},
				]
			}
		}
	}
}

pub fn lazy_with[I, O](getter fn (I) types.Schema[I, O]) types.Schema[I, O] {
	return types.Schema[I, O]{
		type_name: 'lazy'
		expects:   'unknown'
		run:       fn [getter] [I, O](input I, config types.Config) types.Dataset[O] {
			return types.run[I, O](getter(input), input, config)
		}
	}
}
