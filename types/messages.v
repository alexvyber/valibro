module types

// Context owns configuration and localization; no process-global mutable state is required.
pub struct Messages {
pub:
	defaults map[string]ErrorMessage
	schema   map[string]ErrorMessage
	specific map[string]map[string]ErrorMessage
}

pub struct Context {
pub mut:
	config Config
}

pub struct DefaultMessage {
pub:
	text string
}

pub enum IssueKind {
	validation
	schema
	transformation
}
