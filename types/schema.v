module types

// Dataset carries the current value and accumulated issues through a pipeline.
pub struct Dataset[T] {
pub:
	typed     bool = true
	value     T
	issues    []Issue
	exception ?IError
	raw_value ?NativeValue
}

// Schema is immutable and can be reused across parsing calls.
pub struct Schema[I, O] {
pub:
	type_name                string
	wrapped_schema           ?WrappedSchema
	expects                  string
	message                  ?ErrorMessage
	kind                     string = 'schema'
	default_value            ?I
	default_provider         DefaultProvider[I]
	default_context_provider DefaultContextProvider[I]
	fallback_value           ?O
	fallback_provider        FallbackProvider[O]
	annotations              Annotations
	native_examples          Examples[O]
	run                      fn (I, Config) Dataset[O] @[required]
}

// Keep pointers, sum types, and value calls in separate compiler branches.
// V 0.5.2 otherwise retains argument coercions across generic instantiations.
pub fn run[I, O](schema Schema[I, O], input I, config Config) Dataset[O] {
	$if I is $pointer {
		result := schema.run(input, config)
		return resolve_dataset[O](result, config)
	} $else $if I is $sumtype {
		result := schema.run(input, config)
		return resolve_dataset[O](result, config)
	} $else {
		result := schema.run(input, config)
		return resolve_dataset[O](result, config)
	}
}

pub fn run_transformation[I, O](action Transformation[I, O], input I, configs ...Config) Dataset[O] {
	settings := if configs.len > 0 { configs[0] } else { Config{} }
	if action.context_runner.available {
		return resolve_dataset[O](action.context_runner.run(Dataset[I]{ value: input }, settings),
			settings)
	}
	$if I is $pointer {
		result := action.run(input)
		return resolve_dataset[O](result, settings)
	} $else $if I is $sumtype {
		result := action.run(input)
		return resolve_dataset[O](result, settings)
	} $else {
		result := action.run(input)
		return resolve_dataset[O](result, settings)
	}
}

pub fn run_action[T](action Action[T], input T, configs ...Config) Dataset[T] {
	settings := if configs.len > 0 { configs[0] } else { Config{} }
	$if T is $pointer {
		result := action.run(input)
		return resolve_dataset[T](result, settings)
	} $else $if T is $sumtype {
		result := action.run(input)
		return resolve_dataset[T](result, settings)
	} $else {
		result := action.run(input)
		return resolve_dataset[T](result, settings)
	}
}
