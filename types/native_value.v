module types

import x.json2

type NativeEquality = fn (left voidptr, right voidptr) bool

// A GC-owned, signature-checked native value preserves outputs across type changes.
pub struct NativeValue {
	type_name string
	equal     ?NativeEquality
	data      voidptr = unsafe { nil }
}

struct ValueBox[T] {
	value T
}

pub fn value_of[T](value T) NativeValue {
	// Separate AST nodes avoid V 0.5.2 retaining pointer autoref flags for value instances.
	$if T is $pointer {
		boxed := &ValueBox[T]{
			value: value
		}
		return boxed_native_value[T](boxed)
	} $else {
		boxed := &ValueBox[T]{
			value: value
		}
		return boxed_native_value[T](boxed)
	}
}

fn boxed_native_value[T](boxed &ValueBox[T]) NativeValue {
	return NativeValue{
		type_name: typeof[T]().name
		equal:     fn [T](left voidptr, right voidptr) bool {
			a := unsafe { &ValueBox[T](left) }
			b := unsafe { &ValueBox[T](right) }
			return native_set_equal[T](a.value, b.value)
		}
		data:      voidptr(boxed)
	}
}

pub fn value_is[T](value NativeValue) bool {
	return value.type_name == typeof[T]().name && value.data != unsafe { nil }
}

pub fn value_as[T](value NativeValue) !T {
	if !value_is[T](value) { return error('Native value has a different type') }
	boxed := unsafe { &ValueBox[T](value.data) }
	return boxed.value
}

// Invalid dates have an explicit native marker instead of malformed time.Time fields.
pub struct InvalidDate {}

pub fn (value InvalidDate) to_json_value(key string) !Maybe[json2.Any] {
	_ = value
	_ = key
	return some(json2.Any(json2.Null{}))
}

pub struct RawArray {
pub:
	items []NativeValue
}

pub struct RawSet {
pub:
	items []NativeValue
}

pub struct RawEntry {
pub:
	key   NativeValue
	value NativeValue
}

pub struct RawMap {
pub:
	entries []RawEntry
}

pub struct RawObject {
pub:
	entries []RawEntry
}

pub struct RawStruct[T] {
pub:
	value  T
	keys   []string
	fields map[string]NativeValue
}

pub fn raw_entry_set(mut entries []RawEntry, key NativeValue, value NativeValue) {
	for index, entry in entries {
		if raw_equal(entry.key, key) {
			entries[index] = RawEntry{
				key:   entry.key
				value: value
			}
			return
		}
	}
	entries << RawEntry{
		key:   key
		value: value
	}
}

pub fn raw_set(items []NativeValue) RawSet {
	mut unique := []NativeValue{}
	for original in items {
		item := normalize_raw_set_item(original)
		mut found := false
		for existing in unique {
			if raw_equal(existing, item) {
				found = true
				break
			}
		}
		if !found { unique << item }
	}
	return RawSet{
		items: unique
	}
}

fn raw_equal(a NativeValue, b NativeValue) bool {
	if a.type_name != b.type_name { return false }
	if a.data == unsafe { nil } || b.data == unsafe { nil } { return false }
	if equal := a.equal { return equal(a.data, b.data) }
	return a.data == b.data
}

// Compare valid output keys using the caller's native equality even in mixed raw output.
pub fn raw_entry_set_with[T](mut entries []RawEntry, key NativeValue, value NativeValue, equal fn (T, T) bool) {
	for index, entry in entries {
		mut same := raw_equal(entry.key, key)
		if value_is[T](entry.key) && value_is[T](key) {
			left := value_as[T](entry.key) or { panic(err) }
			right := value_as[T](key) or { panic(err) }
			same = equal(left, right)
		}
		if same {
			entries[index] = RawEntry{
				key:   entry.key
				value: value
			}
			return
		}
	}
	entries << RawEntry{
		key:   key
		value: value
	}
}

pub fn raw_set_with[T](items []NativeValue, equal fn (T, T) bool) RawSet {
	mut entries := []RawEntry{}
	for item in items {
		raw_entry_set_with[T](mut entries, item, item, equal)
	}
	return RawSet{
		items: entries.map(it.key)
	}
}

fn normalize_raw_set_item(value NativeValue) NativeValue {
	if value_is[f32](value) {
		number := value_as[f32](value) or { return value }
		if number == 0 { return value_of(f32(0)) }
	}
	if value_is[f64](value) {
		number := value_as[f64](value) or { return value }
		if number == 0 { return value_of(f64(0)) }
	}
	if value_is[json2.Any](value) {
		number := value_as[json2.Any](value) or { return value }
		if number is f64 && number == 0 { return value_of(json2.Any(0.0)) }
		if number is f32 && number == 0 { return value_of(json2.Any(f32(0))) }
	}
	return value
}
