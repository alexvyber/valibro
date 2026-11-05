module valibro

import math.big
import time
import valibro.schemas
import valibro.types

pub fn string(messages ...types.ErrorMessage) types.Schema[string, string] {
	return schemas.string(...messages)
}

pub fn literal[T](requirement T, messages ...types.ErrorMessage) types.Schema[T, T] {
	return schemas.literal[T](requirement, ...messages)
}

pub fn picklist[T](requirements []T, messages ...types.ErrorMessage) types.Schema[T, T] {
	return schemas.picklist[T](requirements, ...messages)
}

pub fn custom[T](predicate fn (T) bool, messages ...types.ErrorMessage) types.Schema[T, T] {
	return schemas.custom[T](predicate, ...messages)
}

pub fn unknown[T]() types.Schema[T, T] {
	return schemas.unknown[T]()
}

pub fn any_value[T]() types.Schema[T, T] {
	return schemas.any_value[T]()
}

pub fn never[T](messages ...types.ErrorMessage) types.Schema[T, T] {
	return schemas.never[T](...messages)
}

pub fn lazy[I, O](getter fn () types.Schema[I, O]) types.Schema[I, O] {
	return schemas.lazy[I, O](getter)
}

pub fn union[I, O](options []types.Schema[I, O], messages ...types.ErrorMessage) types.Schema[I, O] {
	return schemas.union[I, O](options, ...messages)
}

pub fn nan(messages ...types.ErrorMessage) types.Schema[f64, f64] {
	return schemas.nan(...messages)
}

pub fn lazy_with[I, O](getter fn (I) types.Schema[I, O]) types.Schema[I, O] {
	return schemas.lazy_with[I, O](getter)
}

pub fn number(messages ...types.ErrorMessage) types.Schema[f64, f64] {
	return schemas.number(...messages)
}

pub fn number_of[T](messages ...types.ErrorMessage) types.Schema[T, T] {
	return schemas.number_of[T](...messages)
}

pub fn boolean(messages ...types.ErrorMessage) types.Schema[bool, bool] {
	return schemas.boolean(...messages)
}

pub fn bigint(messages ...types.ErrorMessage) types.Schema[big.Integer, big.Integer] {
	return schemas.bigint(...messages)
}

pub fn date(messages ...types.ErrorMessage) types.Schema[time.Time, time.Time] {
	return schemas.date(...messages)
}

pub fn null_schema() types.Schema[types.Null, types.Null] {
	return schemas.null_schema()
}

pub fn undefined_schema() types.Schema[types.Undefined, types.Undefined] {
	return schemas.undefined_schema()
}

pub fn void_schema() types.Schema[types.Undefined, types.Undefined] {
	return schemas.void_schema()
}

pub fn symbol() types.Schema[types.Symbol, types.Symbol] {
	return schemas.symbol()
}

pub fn enum_schema[T](values []T, messages ...types.ErrorMessage) types.Schema[T, T] {
	return schemas.enum_schema[T](values, ...messages)
}

pub fn field[P, Q, I, O](name string, getter fn (P) I, setter fn (Q, O) Q, schema types.Schema[I, O]) types.Field[P, Q] {
	return schemas.field[P, Q, I, O](name, getter, setter, schema)
}

pub fn object[T](fields ...types.Field[T, T]) types.Schema[T, T] {
	return schemas.object[T](...fields)
}

pub fn object_from[I, O](initial fn (I) O, fields []types.Field[I, O]) types.Schema[I, O] {
	return schemas.object_from[I, O](initial, fields)
}

pub fn blob() types.Schema[types.Blob, types.Blob] {
	return schemas.blob()
}

pub fn file() types.Schema[types.File, types.File] {
	return schemas.file()
}

pub fn instance[T]() types.Schema[T, T] {
	return schemas.instance[T]()
}
