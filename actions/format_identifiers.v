module actions

import valibro.internal.formats
import valibro.types

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn bic(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('bic', fn (input string) bool {
		return formats.valid_bic(input)
	}, messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn cuid2(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('cuid2', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn nanoid(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('nanoid', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn ksuid(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('ksuid', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn ulid(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('ulid', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn uuid(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('uuid', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn isrc(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('isrc', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn jws_compact(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('jws_compact', messages)
}
