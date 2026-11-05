module types

import rand
import sync
import x.json2

pub struct Null {}

pub struct Undefined {}

pub struct Symbol {
	id string
pub:
	description string
}

pub fn symbol(description string) Symbol {
	return Symbol{
		id:          rand.uuid_v4()
		description: description
	}
}

struct FutureState[T] {
mut:
	mutex    sync.Mutex
	resolved bool
	result   SafeParseResult[T]
	channel  chan SafeParseResult[T]
}

pub struct Future[T] {
pub:
	state &FutureState[T] @[required]
}

pub fn new_future[T](result chan SafeParseResult[T]) Future[T] {
	return Future[T]{
		state: &FutureState[T]{
			channel: result
		}
	}
}

pub fn (future Future[T]) await() !T {
	mut state := future.state
	state.mutex.lock()
	defer { state.mutex.unlock() }
	if !state.resolved {
		state.result = <-state.channel
		state.resolved = true
	}
	return future_output[T](state.result)
}

fn future_output[T](result SafeParseResult[T]) !T {
	if exception := result.exception { return exception }
	if result.success { return unwrap_future_output[T](result.output) }
	return ValidationError{
		issues: if result.issues.len > 0 { result.issues } else { [
				new_issue('await', 'Future produced no output', 'output', 'closed channel'),
			] }
	}
}

pub fn awaiting[T]() Transformation[Future[T], T] {
	return Transformation[Future[T], T]{
		type_name: 'await'
		run:       fn [T](input Future[T]) Dataset[T] {
			value := input.await() or {
				return Dataset[T]{
					typed:     false
					exception: err
				}
			}
			return Dataset[T]{
				value: value
			}
		}
	}
}

fn unwrap_future_output[T](value ?T) !T {
	return value or { return error('Future produced no output') }
}

pub fn (future Future[T]) to_json_value(key string) !Maybe[json2.Any] {
	_ = future
	_ = key
	return error('Await a Future before JSON serialization')
}
