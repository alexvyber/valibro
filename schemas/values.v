module schemas

import valibro.types

pub fn null_schema() types.Schema[types.Null, types.Null] {
	return native_schema[types.Null]('null', [])
}

pub fn undefined_schema() types.Schema[types.Undefined, types.Undefined] {
	return native_schema[types.Undefined]('undefined', [])
}

pub fn void_schema() types.Schema[types.Undefined, types.Undefined] {
	return native_schema[types.Undefined]('void', [])
}

pub fn symbol() types.Schema[types.Symbol, types.Symbol] {
	return native_schema[types.Symbol]('symbol', [])
}

pub fn promise[T]() types.Schema[types.Future[T], types.Future[T]] {
	return native_schema[types.Future[T]]('promise', [])
}

pub fn enum_schema[T](values []T, messages ...types.ErrorMessage) types.Schema[T, T] {
	schema := picklist(values, ...messages)
	return types.Schema[T, T]{
		...schema
		type_name: 'enum'
		run:       fn [schema] [T](input T, config types.Config) types.Dataset[T] {
			result := schema.run(input, config)
			mut issues := []types.Issue{}
			for issue in result.issues {
				issues << types.Issue{
					...issue
					code: 'enum'
				}
			}
			return types.Dataset[T]{
				...result
				issues: issues
			}
		}
	}
}

pub fn undefinedable[I, O](schema types.Schema[I, O], defaults ...I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_schema(schema, 'undefinedable', defaults)
}
