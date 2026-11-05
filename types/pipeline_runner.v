module types

pub struct PipelineRunner[I, O] {
pub:
	available bool
	run       fn (dataset Dataset[I], config Config) Dataset[O] @[required]
}

pub fn contextual_action[T](name string, kind ActionKind, operation fn (dataset Dataset[T], config Config) Dataset[T]) Action[T] {
	return Action[T]{
		type_name:      name
		kind:           kind
		context_runner: PipelineRunner[T, T]{
			available: true
			run:       operation
		}
		run:            fn [operation] [T](input T) Dataset[T] {
			return operation(Dataset[T]{ value: input }, Config{})
		}
	}
}

pub fn contextual_transformation[I, O](name string, operation fn (dataset Dataset[I], config Config) Dataset[O]) Transformation[I, O] {
	return Transformation[I, O]{
		type_name:      name
		context_runner: PipelineRunner[I, O]{
			available: true
			run:       operation
		}
		run:            fn [operation] [I, O](input I) Dataset[O] {
			return operation(Dataset[I]{ value: input }, Config{})
		}
	}
}

pub fn apply_action[T](action Action[T], dataset Dataset[T], config Config) Dataset[T] {
	if action.context_runner.available {
		return resolve_dataset[T](action.context_runner.run(dataset, config), config)
	}
	if !dataset.typed { return dataset }
	next := run_action[T](action, dataset.value, config)
	if next.exception != none { return next }
	mut issues := dataset.issues.clone()
	issues << next.issues
	return Dataset[T]{
		...next
		issues: issues
	}
}
