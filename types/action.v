module types

pub enum ActionKind {
	metadata
	validation
	transformation
}

// Actions validate or transform one statically typed value.
pub struct Action[T] {
pub:
	kind        ActionKind
	type_name   string
	annotations Annotations
	run         fn (T) Dataset[T] @[required]
}
