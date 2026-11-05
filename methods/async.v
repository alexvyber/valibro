module methods

import valibro.types

// V callbacks can perform I/O directly. These adapters move the whole parse onto a worker.
pub fn safe_parse_async[I, O](schema types.Schema[I, O], input I) chan types.SafeParseResult[O] {
	return safe_parse_async_with_config[I, O](schema, input, types.Config{})
}

pub fn safe_parse_async_with_config[I, O](schema types.Schema[I, O], input I, config types.Config) chan types.SafeParseResult[O] {
	output := chan types.SafeParseResult[O]{cap: 1}
	job := fn [schema, input, config, output] [I, O]() {
		result := safe_parse_checked[I, O](schema, input, config) or {
			types.SafeParseResult[O]{
				exception: err
			}
		}
		output <- result
		output.close()
	}
	spawn job()
	return output
}

pub fn parser_async[I, O](schema types.Schema[I, O]) fn (I) types.Future[O] {
	return fn [schema] [I, O](input I) types.Future[O] {
		return types.new_future[O](safe_parse_async[I, O](schema, input))
	}
}

pub fn safe_parser_async[I, O](schema types.Schema[I, O]) fn (I) chan types.SafeParseResult[O] {
	return fn [schema] [I, O](input I) chan types.SafeParseResult[O] {
		return safe_parse_async[I, O](schema, input)
	}
}
