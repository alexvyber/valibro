module types

pub type MessageFunction = fn (Issue) string

pub type ErrorMessage = MessageFunction | string

pub fn resolve_message(message ErrorMessage, issue Issue) string {
	return match message {
		string { message }
		MessageFunction { message(issue) }
	}
}

pub fn new_issue(code string, message ErrorMessage, expected string, received string) Issue {
	issue := Issue{
		code:     code
		expected: expected
		received: received
	}
	return Issue{
		...issue
		message: resolve_message(message, issue)
	}
}
