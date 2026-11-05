module types

import rand

pub type MessageFunction = fn (Issue) string

pub struct MessageCallback {
	identity string
pub:
	callback MessageFunction @[required]
}

pub fn (message MessageCallback) cache_identity() string {
	return message.identity
}

pub fn identified_message(callback MessageFunction) ErrorMessage {
	return MessageCallback{
		identity: rand.uuid_v4()
		callback: callback
	}
}

pub type ErrorMessage = DefaultMessage | MessageFunction | MessageCallback | string

pub fn resolve_message(message ErrorMessage, issue Issue) string {
	return match message {
		string { message }
		DefaultMessage { message.text }
		MessageFunction { message(issue) }
		MessageCallback { message.callback(issue) }
	}
}

pub fn issue_of_kind(code string, message ErrorMessage, expected string, received string, kind IssueKind, fallbacks ...string) Issue {
	prefix := 'Invalid ' + code.replace('_', ' ') + ': ' +
		if expected == '' { 'Received ' } else { 'Expected ' + expected + ' but received ' }
	fallback := if fallbacks.len > 0 { fallbacks[0] } else { prefix + received }
	issue := Issue{
		code:           code
		kind:           kind
		custom_message: message !is DefaultMessage
		expected:       expected
		received:       received
	}
	if message is MessageFunction { return Issue{
			...issue
			message:          fallback
			message_provider: MessageProvider{
				active: true
				get:    message
			}
		} }
	if message is MessageCallback { return Issue{
			...issue
			message:          fallback
			message_provider: MessageProvider{
				active: true
				get:    message.callback
			}
		} }
	return Issue{
		...issue
		message: resolve_message(message, issue)
	}
}

pub fn new_issue(code string, message ErrorMessage, expected string, received string, fallbacks ...string) Issue {
	return issue_of_kind(code, message, expected, received, .validation, ...fallbacks)
}

pub fn schema_issue(code string, message ErrorMessage, expected string, received string) Issue {
	return issue_of_kind(code, message, expected, received, .schema)
}

pub fn schema_type_issue(code string, message ErrorMessage, expected string, received string, label string) Issue {
	prefix := 'Invalid ' + label + ': ' + if expected == '' {
		'Received '
	} else {
		'Expected ' + expected + ' but received '
	}
	resolved := if message is DefaultMessage { ErrorMessage(DefaultMessage{
			text: prefix + received
		}) } else { message }
	return issue_of_kind(code, resolved, expected, received, .schema, prefix + received)
}
