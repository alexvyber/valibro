module valibro

import valibro.actions
import valibro.schemas
import valibro.types

pub fn length_of[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return actions.length_of[T](requirement, ...messages)
}

pub fn min_length_of[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return actions.min_length_of[T](requirement, ...messages)
}

pub fn max_length_of[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return actions.max_length_of[T](requirement, ...messages)
}

pub fn not_length_of[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return actions.not_length_of[T](requirement, ...messages)
}

pub fn every_item[T](predicate fn (T, int) bool, messages ...types.ErrorMessage) types.Action[[]T] {
	return actions.every_item[T](predicate, ...messages)
}

pub fn some_item[T](predicate fn (T, int) bool, messages ...types.ErrorMessage) types.Action[[]T] {
	return actions.some_item[T](predicate, ...messages)
}

pub fn check_items[T](predicate fn (T, int) bool, messages ...types.ErrorMessage) types.Action[[]T] {
	return actions.check_items[T](predicate, ...messages)
}

pub fn includes_item[T](requirement T, messages ...types.ErrorMessage) types.Action[[]T] {
	return actions.includes_item[T](requirement, ...messages)
}

pub fn excludes_item[T](requirement T, messages ...types.ErrorMessage) types.Action[[]T] {
	return actions.excludes_item[T](requirement, ...messages)
}

pub fn empty_of[T](messages ...types.ErrorMessage) types.Action[T] {
	return actions.empty_of[T](...messages)
}

pub fn non_empty_of[T](messages ...types.ErrorMessage) types.Action[T] {
	return actions.non_empty_of[T](...messages)
}

// Array-aware callbacks receive the original input array.

pub fn array[I, O](item types.Schema[I, O]) types.Schema[[]I, []O] {
	return schemas.array_schema[I, O](item)
}

pub fn record[I, O](key types.Schema[string, string], value types.Schema[I, O]) types.Schema[map[string]I, map[string]O] {
	return schemas.record[I, O](key, value)
}

pub fn set[I, O](item types.Schema[I, O]) types.Schema[types.Set[I], types.Set[O]] {
	return schemas.set[I, O](item)
}

pub fn map_schema[K, L, I, O](key types.Schema[K, L], value types.Schema[I, O]) types.Schema[map[K]I, map[L]O] {
	return schemas.map_schema[K, L, I, O](key, value)
}

pub fn mime_type[T](requirements []string, messages ...types.ErrorMessage) types.Action[T] {
	return actions.mime_type[T](requirements, ...messages)
}

pub fn entry_map[K, L, I, O](key types.Schema[K, L], value types.Schema[I, O], equal fn (L, L) bool) types.Schema[types.EntryMap[K, I], types.EntryMap[L, O]] {
	return schemas.entry_map(key, value, equal)
}

pub fn set_with[I, O](item types.Schema[I, O], equal fn (O, O) bool) types.Schema[types.Set[I], types.Set[O]] {
	return schemas.set_with(item, equal)
}
