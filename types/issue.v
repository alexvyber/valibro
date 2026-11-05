module types

// Paths retain the distinction between object keys and array indexes.
pub type PathSegment = int | string

pub struct Issue {
	context_resolved bool
pub:
	lang                 string
	abort_early          bool
	abort_pipe_early     bool
	message_provider     MessageProvider
	code                 string
	kind                 IssueKind
	custom_message       bool
	message              string
	expected             string
	received             string
	path                 []PathSegment
	path_types           []string
	path_keys            []NativeValue
	path_present         bool
	dot_path_unavailable bool
	issues               []Issue
}

pub struct ValidationError {
pub:
	issues []Issue
}

pub fn (err ValidationError) msg() string {
	return err.issues.map(it.message).join('; ')
}

pub fn (err ValidationError) code() int {
	return 1
}

pub struct RangeError {
pub:
	message string
}

pub fn (err RangeError) msg() string {
	return err.message
}

pub fn (err RangeError) code() int {
	return 1
}

pub struct TypeError {
pub:
	message string
}

pub fn (err TypeError) msg() string {
	return err.message
}

pub fn (err TypeError) code() int {
	return 1
}
