module types

// Fallback providers can inspect the failed output and its resolved issues.
// Introspection without a parse supplies none for the dataset.
pub struct FallbackProvider[T] {
pub:
	available bool
	get       fn (?Dataset[T], Config) T @[required]
}
