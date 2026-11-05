module types

// Presence distinguishes absent entries, explicit undefined, null, and a value.
pub enum Presence {
	missing
	undefined
	null
	value
}
pub struct Maybe[T] {
pub:
	state Presence
	value T
}

pub fn some[T](value T) Maybe[T] {
	return Maybe[T]{
		state: .value
		value: value
	}
}

pub fn missing[T]() Maybe[T] {
	return Maybe[T]{
		state: .missing
	}
}

pub fn undefined_value[T]() Maybe[T] {
	return Maybe[T]{
		state: .undefined
	}
}

pub fn null_value[T]() Maybe[T] {
	return Maybe[T]{
		state: .null
	}
}

// Internal generic-presence protocol shared with native adapters. Not a custom-value hook.
pub interface NativeMaybe {
	state Presence
	maybe_state() Presence
}

pub fn (value Maybe[T]) maybe_state() Presence {
	return value.state
}
