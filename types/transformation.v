module types

// Transformation changes the output type. Compose with methods.pipe_to.
pub struct Transformation[I, O] {
pub:
	type_name      string
	context_runner PipelineRunner[I, O]
	kind           string = 'transformation'
	run            fn (I) Dataset[O] @[required]
}

pub struct ParseBooleanConfig {
pub:
	truthy []string = ['true', '1', 'yes', 'y', 'on', 'enabled']
	falsy  []string = ['false', '0', 'no', 'n', 'off', 'disabled']
}
