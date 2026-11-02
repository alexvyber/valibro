module types

// Dataset carries the current value and accumulated issues through a pipeline.
pub struct Dataset[T] {
pub:
	typed  bool = true
	value  T
	issues []Issue
}

// Schema is immutable and can be reused across parsing calls.
pub struct Schema[I, O] {
pub:
	type_name   string
	annotations Annotations
	run         fn (I, Config) Dataset[O] @[required]
}
