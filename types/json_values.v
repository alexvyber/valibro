module types

import x.json2

pub fn (value Function[I, O]) to_json_value(key string) !Maybe[json2.Any] {
	_ = value
	_ = key
	return error('Functions cannot be encoded as JSON')
}

pub fn (value FallibleFunction[I, O]) to_json_value(key string) !Maybe[json2.Any] {
	_ = value
	_ = key
	return error('Functions cannot be encoded as JSON')
}

pub interface FunctionValue {
	function_value() bool
}

pub fn (value Function[I, O]) function_value() bool {
	return true
}

pub fn (value FallibleFunction[I, O]) function_value() bool {
	return true
}
