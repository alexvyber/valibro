module types

// Paths retain the distinction between object keys and array indexes.
pub type PathSegment = int | string

pub struct Issue {
pub:
	code     string
	message  string
	expected string
	received string
	path     []PathSegment
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
