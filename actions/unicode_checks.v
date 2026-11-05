module actions

import valibro.types
import valibro.unicode

pub fn graphemes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('graphemes', requirement, '=', fn (input string) int {
		return unicode.grapheme_count(input)
	}, messages)
}

pub fn min_graphemes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('min_graphemes', requirement, '>=', fn (input string) int {
		return unicode.grapheme_count(input)
	}, messages)
}

pub fn max_graphemes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('max_graphemes', requirement, '<=', fn (input string) int {
		return unicode.grapheme_count(input)
	}, messages)
}

pub fn not_graphemes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('not_graphemes', requirement, '!=', fn (input string) int {
		return unicode.grapheme_count(input)
	}, messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn emoji(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('emoji', fn (input string) bool {
		return unicode.is_emoji(input)
	}, messages)
}

pub fn words(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('words', requirement, '=', fn (input string) int {
		return unicode.word_count(input)
	}, messages)
}

pub fn min_words(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('min_words', requirement, '>=', fn (input string) int {
		return unicode.word_count(input)
	}, messages)
}

pub fn max_words(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('max_words', requirement, '<=', fn (input string) int {
		return unicode.word_count(input)
	}, messages)
}

pub fn not_words(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return count_check[string]('not_words', requirement, '!=', fn (input string) int {
		return unicode.word_count(input)
	}, messages)
}
