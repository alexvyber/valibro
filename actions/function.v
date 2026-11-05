module actions

import valibro.methods
import valibro.types

// One native argument can pack several arguments in a struct or array.
pub fn args[I, O, R](schema types.Schema[I, O]) types.Transformation[types.Function[O, R], types.FallibleFunction[I, R]] {
	return types.contextual_transformation[types.Function[O, R], types.FallibleFunction[I, R]]('args', fn [schema] [I, O, R](dataset types.Dataset[types.Function[O, R]], config types.Config) types.Dataset[types.FallibleFunction[I, R]] {
		input := dataset.value
		wrapped := fn [schema, input, config] [I, O, R](argument I) !R {
			checked := methods.parse_with_config[I, O](schema, argument, config)!
			return input.call(checked)
		}
		return types.Dataset[types.FallibleFunction[I, R]]{
			value: types.FallibleFunction[I, R]{
				call: wrapped
			}
		}
	})
}

pub fn returns[I, R, S](schema types.Schema[R, S]) types.Transformation[types.Function[I, R], types.FallibleFunction[I, S]] {
	return types.contextual_transformation[types.Function[I, R], types.FallibleFunction[I, S]]('returns', fn [schema] [I, R, S](dataset types.Dataset[types.Function[I, R]], config types.Config) types.Dataset[types.FallibleFunction[I, S]] {
		input := dataset.value
		wrapped := fn [schema, input, config] [I, R, S](argument I) !S {
			return methods.parse_with_config[R, S](schema, input.call(argument), config)
		}
		return types.Dataset[types.FallibleFunction[I, S]]{
			value: types.FallibleFunction[I, S]{
				call: wrapped
			}
		}
	})
}

pub fn returns_checked[I, R, S](schema types.Schema[R, S]) types.Transformation[types.FallibleFunction[I, R], types.FallibleFunction[I, S]] {
	return types.contextual_transformation[types.FallibleFunction[I, R], types.FallibleFunction[I, S]]('returns', fn [schema] [I, R, S](dataset types.Dataset[types.FallibleFunction[I, R]], config types.Config) types.Dataset[types.FallibleFunction[I, S]] {
		input := dataset.value
		wrapped := fn [schema, input, config] [I, R, S](argument I) !S {
			return methods.parse_with_config[R, S](schema, input.call(argument)!, config)
		}
		return types.Dataset[types.FallibleFunction[I, S]]{
			value: types.FallibleFunction[I, S]{
				call: wrapped
			}
		}
	})
}

pub fn await_future[T]() types.Transformation[types.Future[T], T] {
	return types.awaiting[T]()
}
