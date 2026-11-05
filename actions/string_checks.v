module actions

import valibro.types

pub fn empty(messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('empty', 0, '=', fn (input string) int {
		return input.runes().len
	}, messages)
}

pub fn non_empty(messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('non_empty', 0, '!=', fn (input string) int {
		return input.runes().len
	}, messages)
}

pub fn includes(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	text := custom_message(messages, '')
	content := '"' + requirement + '"'
	expected := content
	received := '!' + content
	return types.Action[string]{
		kind:      .validation
		type_name: 'includes'
		run:       fn [requirement, text, expected, received] (input string) types.Dataset[string] {
			if input.contains(requirement) { return types.Dataset[string]{
					value: input
				} }
			return validation_failure[string](input, 'includes', 'content', expected, received,
				text)
		}
	}
}

pub fn excludes(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	text := custom_message(messages, '')
	content := '"' + requirement + '"'
	expected := '!' + content
	received := content
	return types.Action[string]{
		kind:      .validation
		type_name: 'excludes'
		run:       fn [requirement, text, expected, received] (input string) types.Dataset[string] {
			if !input.contains(requirement) { return types.Dataset[string]{
					value: input
				} }
			return validation_failure[string](input, 'excludes', 'content', expected, received,
				text)
		}
	}
}

pub fn starts_with(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	text := custom_message(messages, '')
	expected := '"' + requirement + '"'
	count := requirement.runes().len
	return types.Action[string]{
		kind:      .validation
		type_name: 'starts_with'
		run:       fn [requirement, text, expected, count] (input string) types.Dataset[string] {
			if input.starts_with(requirement) { return types.Dataset[string]{
					value: input
				} }
			units := input.runes()
			fragment_length := if units.len < count { units.len } else { count }
			mut received := [rune(34)]
			received << units[..fragment_length]
			received << rune(34)
			return validation_failure[string](input, 'starts_with', 'start', expected,
				received.string(), text)
		}
	}
}

pub fn ends_with(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	text := custom_message(messages, '')
	expected := '"' + requirement + '"'
	count := requirement.runes().len
	return types.Action[string]{
		kind:      .validation
		type_name: 'ends_with'
		run:       fn [requirement, text, expected, count] (input string) types.Dataset[string] {
			if input.ends_with(requirement) { return types.Dataset[string]{
					value: input
				} }
			units := input.runes()
			fragment_length := if units.len < count { units.len } else { count }
			mut received := [rune(34)]
			received << units[units.len - fragment_length..]
			received << rune(34)
			return validation_failure[string](input, 'ends_with', 'end', expected,
				received.string(), text)
		}
	}
}

fn string_predicate(code string, predicate fn (string) bool, messages []types.ErrorMessage) types.Action[string] {
	text := custom_message(messages, '')
	return types.Action[string]{
		kind:      .validation
		type_name: code
		run:       fn [code, predicate, text] (input string) types.Dataset[string] {
			if predicate(input) { return types.Dataset[string]{
					value: input
				} }
			return format_failure(input, code, text)
		}
	}
}
