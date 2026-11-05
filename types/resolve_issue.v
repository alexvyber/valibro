module types

pub struct MessageProvider {
pub:
	active bool
	get    fn (Issue) string = original_issue_message
}

pub fn resolve_dataset[T](dataset Dataset[T], config Config) Dataset[T] {
	if dataset.exception != none { return dataset }
	mut issues := []Issue{cap: dataset.issues.len}
	for issue in dataset.issues {
		issues << resolve_issue(issue, config)
	}
	return Dataset[T]{
		...dataset
		issues: issues
	}
}

pub fn resolve_issue(issue Issue, config Config) Issue {
	if issue.context_resolved { return issue }
	mut children := []Issue{}
	for child in issue.issues {
		children << resolve_issue(child, config)
	}
	candidate := Issue{
		...issue
		issues:           children
		lang:             config.lang
		abort_early:      config.abort_early
		abort_pipe_early: config.abort_pipe_early
		context_resolved: true
	}
	if issue.message_provider.active {
		return Issue{
			...candidate
			message:          issue.message_provider.get(candidate)
			message_provider: MessageProvider{}
			custom_message:   true
		}
	}
	if issue.custom_message { return candidate }
	if specific := config.messages.specific[issue.code] {
		if message := specific[config.lang] { return resolved_message(candidate, message) }
	}
	if issue.kind == .schema {
		if message := config.messages.schema[config.lang] {
			return resolved_message(candidate, message)
		}
	}
	if message := config.message { return resolved_message(candidate, message) }
	if message := config.messages.defaults[config.lang] {
		return resolved_message(candidate, message)
	}
	return candidate
}

fn resolved_message(issue Issue, message ErrorMessage) Issue {
	return Issue{
		...issue
		message:        resolve_message(message, issue)
		custom_message: true
	}
}

fn original_issue_message(issue Issue) string {
	return issue.message
}
