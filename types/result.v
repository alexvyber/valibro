module types

pub struct SafeParseResult[T] {
pub:
	success bool
	// Output is absent whenever validation fails.
	output ?T
	issues []Issue
}
