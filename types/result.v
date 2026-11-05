module types

pub struct SafeParseResult[T] {
pub:
	raw_output NativeValue
	success    bool
	typed      bool
	exception  ?IError
	// Output is absent whenever validation fails.
	output ?T
	issues []Issue
}
