module methods

import valibro.types

fn apply_messages[T](dataset types.Dataset[T], config types.Config) types.Dataset[T] {
	return types.resolve_dataset[T](dataset, config)
}
