module valibro

import valibro.actions
import valibro.methods
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

pub fn entries[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return actions.entries[T](requirement, ...messages)
}

pub fn min_entries[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return actions.min_entries[T](requirement, ...messages)
}

pub fn max_entries[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return actions.max_entries[T](requirement, ...messages)
}

pub fn not_entries[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return actions.not_entries[T](requirement, ...messages)
}

pub fn size[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return actions.size[T](requirement, ...messages)
}

pub fn min_size[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return actions.min_size[T](requirement, ...messages)
}

pub fn max_size[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return actions.max_size[T](requirement, ...messages)
}

pub fn not_size[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return actions.not_size[T](requirement, ...messages)
}

pub fn map_items[I, O](operation fn (I, int) O) types.Transformation[[]I, []O] {
	return actions.map_items[I, O](operation)
}

pub fn filter_items[T](predicate fn (T, int) bool) types.Action[[]T] {
	return actions.filter_items[T](predicate)
}

pub fn find_item[T](predicate fn (T, int) bool) types.Transformation[[]T, types.Maybe[T]] {
	return actions.find_item[T](predicate)
}

pub fn reduce_items[T, A](operation fn (A, T, int) A, initial A) types.Transformation[[]T, A] {
	return actions.reduce_items[T, A](operation, initial)
}

pub fn sort_items[T](compare fn (T, T) int) types.Action[[]T] {
	return actions.sort_items[T](compare)
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

pub fn map_items_with_array[I, O](operation fn (I, int, []I) O) types.Transformation[[]I, []O] {
	return actions.map_items_with_array[I, O](operation)
}

pub fn filter_items_with_array[T](predicate fn (T, int, []T) bool) types.Action[[]T] {
	return actions.filter_items_with_array[T](predicate)
}

pub fn find_item_with_array[T](predicate fn (T, int, []T) bool) types.Transformation[[]T, types.Maybe[T]] {
	return actions.find_item_with_array[T](predicate)
}

pub fn reduce_items_with_array[T, A](operation fn (A, T, int, []T) A, initial A) types.Transformation[[]T, A] {
	return actions.reduce_items_with_array[T, A](operation, initial)
}

pub fn every_item_with_array[T](predicate fn (T, int, []T) bool, messages ...types.ErrorMessage) types.Action[[]T] {
	return actions.every_item_with_array[T](predicate, ...messages)
}

pub fn some_item_with_array[T](predicate fn (T, int, []T) bool, messages ...types.ErrorMessage) types.Action[[]T] {
	return actions.some_item_with_array[T](predicate, ...messages)
}

pub fn check_items_with_array[T](predicate fn (T, int, []T) bool, messages ...types.ErrorMessage) types.Action[[]T] {
	return actions.check_items_with_array[T](predicate, ...messages)
}

pub fn array[I, O](item types.Schema[I, O]) types.Schema[[]I, []O] {
	return schemas.array_schema[I, O](item)
}

pub fn record[I, O](key types.Schema[string, string], value types.Schema[I, O]) types.Schema[map[string]I, map[string]O] {
	return schemas.record[I, O](key, value)
}

pub fn entries_from_list[T](keys []string, value T) map[string]T {
	return methods.entries_from_list[T](keys, value)
}

pub fn entries_from_objects[T](objects ...map[string]T) map[string]T {
	return methods.entries_from_objects[T](...objects)
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
