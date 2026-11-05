module types

pub enum ActionKind {
	metadata
	validation
	transformation
}

// Actions validate or transform one statically typed value.
pub struct Action[T] {
pub:
	kind            ActionKind
	type_name       string
	annotations     Annotations
	native_examples Examples[T]
	context_runner  PipelineRunner[T, T]
	run             fn (T) Dataset[T] @[required]
}
