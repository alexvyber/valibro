module actions

import valibro.internal.formats
import valibro.internal.url as urls
import valibro.types

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn email(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('email', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn rfc_email(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('rfc_email', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn domain(messages ...types.ErrorMessage) types.Action[string] {
	return string_predicate('domain', fn (input string) bool {
		return formats.valid_domain(input)
	}, messages)
}

pub fn url(messages ...types.ErrorMessage) types.Action[string] {
	text := custom_message(messages, '')
	return types.Action[string]{
		kind:      .validation
		type_name: 'url'
		run:       fn [text] (input string) types.Dataset[string] {
			if urls.valid_url(input) { return types.Dataset[string]{
					value: input
				} }
			received := '"' + input + '"'
			resolved_message := if text is types.DefaultMessage { types.ErrorMessage(types.DefaultMessage{
					text: 'Invalid URL: Received ' + received
				}) } else { text }
			return types.Dataset[string]{
				value:  input
				issues: [
					types.new_issue('url', resolved_message, '', received,

						'Invalid URL: Received ' + received),
				]
			}
		}
	}
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn ip(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('ip', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn ipv4(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('ipv4', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn ipv6(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('ipv6', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn mac(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('mac', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn mac48(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('mac48', messages)
}

// Pattern supplied by pinned Valibot; see THIRD_PARTY_NOTICES.md.

pub fn mac64(messages ...types.ErrorMessage) types.Action[string] {
	return upstream_format('mac64', messages)
}
