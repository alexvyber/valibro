module json

import valibro.internal.diagnostics
import x.json2
import valibro.types
import valibro.methods
import valibro.schemas
import valibro.jsoncodec
import math

pub type ShapeRebuilder = fn (entries map[string]Schema) Schema

// Schema validates unknown JSON values and retains structure for shape operations.
pub struct Schema {
pub:
	type_name            string
	shape_rebuilder      ?ShapeRebuilder
	expects              string
	message              ?types.ErrorMessage
	kind                 string = 'schema'
	discriminator        string
	annotations          types.Annotations
	native_examples      types.Examples[json2.Any]
	entries              map[string]Schema
	items                []Schema
	wrapped              []Schema
	optional             bool
	default_value        ?json2.Any
	has_default_provider bool
	default_provider     fn (types.Config) json2.Any = absent_json_default
	fallback_value       ?json2.Any
	fallback_wrapped     []Schema
	mode                 string
	run                  fn (json2.Any, types.Config) types.Dataset[json2.Any] @[required]
}

pub fn native(schema Schema) types.Schema[json2.Any, json2.Any] {
	return types.Schema[json2.Any, json2.Any]{
		default_value:    schema.default_value
		fallback_value:   schema.fallback_value
		default_provider: types.DefaultProvider[json2.Any]{
			available: schema.has_default_provider
			get:       schema.default_provider
		}
		type_name:        schema.type_name
		expects:          schema.expects
		message:          schema.message
		annotations:      schema.annotations
		native_examples:  schema.native_examples
		run:              schema.run
	}
}

pub fn parse(schema Schema, input json2.Any) !json2.Any {
	return methods.parse(native(schema), input)
}

pub fn safe_parse(schema Schema, input json2.Any) types.SafeParseResult[json2.Any] {
	return methods.safe_parse(native(schema), input)
}

pub fn safe_parse_with_config(schema Schema, input json2.Any, config types.Config) types.SafeParseResult[json2.Any] {
	return methods.safe_parse_with_config(native(schema), input, config)
}

pub fn parse_text(schema Schema, input string) !json2.Any {
	return parse(schema, jsoncodec.decode(input)!)
}

pub fn is_valid(schema Schema, input json2.Any) bool {
	return safe_parse(schema, input).success
}

pub fn pipe(schema Schema, actions ...types.Action[json2.Any]) Schema {
	combined := methods.pipe_from_actions(native(schema), actions)
	return Schema{
		...schema
		shape_rebuilder: none
		annotations:     combined.annotations
		native_examples: combined.native_examples
		run:             combined.run
	}
}

fn type_issue(code string, input json2.Any, expected string, messages ...types.ErrorMessage) types.Dataset[json2.Any] {
	text := if messages.len > 0 { messages[0] } else { types.ErrorMessage(types.DefaultMessage{}) }
	expects := match expected {
		'array', 'tuple' { 'Array' }
		'object', 'record' { 'Object' }
		'f64' { 'number' }
		'bool' { 'boolean' }
		else { expected }
	}

	return types.Dataset[json2.Any]{
		typed:  false
		value:  input
		issues: [
			types.schema_type_issue(code, text, expects, diagnostics.issue_value(input), 'type'),
		]
	}
}

// from_schema adapts a native pipeline, with runtime JSON type checks at its boundary.
pub fn from_schema[I, O](schema types.Schema[I, O]) Schema {
	mut examples := []json2.Any{}
	for value in schema.native_examples.values {
		examples << encode_native[O](value)
	}
	return Schema{
		native_examples: types.Examples[json2.Any]{
			present: schema.native_examples.present
			values:  examples
		}
		type_name:       schema.type_name
		expects:         schema.expects
		message:         schema.message
		annotations:     schema.annotations
		run:             fn [schema] [I, O](input json2.Any, config types.Config) types.Dataset[json2.Any] {
			decoded := decode_native[I](input) or {
				expected := if schema.expects != '' { schema.expects } else { typeof[I]().name }
				return type_issue(schema.type_name, input, expected, schema.message or {
					types.DefaultMessage{}
				})
			}
			result := types.run[I, O](schema, decoded, config)
			if exception := result.exception { return types.Dataset[json2.Any]{
					typed:     false
					exception: exception
				} }
			mut output := encode_native[O](result.value)
			if raw := result.raw_value { output = boxed_json_value(raw) or { output } }
			return types.Dataset[json2.Any]{
				typed:  result.typed
				value:  output
				issues: result.issues
			}
		}
	}
}

fn decode_native[T](input json2.Any) !T {
	$if T is string {
		if input is string { return input }
	} $else $if T is bool {
		if input is bool { return input }
	} $else $if T is f64 {
		if types.is_json_number(input) { return input.f64() }
		return error('Expected number')
	} $else $if T is json2.Any {
		return input
	} $else {
		$compile_error('JSON adapters accept native string, bool, f64, or json2.Any inputs; use a custom JSON schema for other types')
	}
	return error('Wrong JSON type')
}

fn encode_native[T](input T) json2.Any {
	$if T is isize {
		return json2.Any(i64(input))
	} $else $if T is usize {
		return json2.Any(u64(input))
	} $else $if T is string || T is bool || T is f64 || T is f32 || T is int || T is i64 || T is u64
		|| T is json2.Any || T is i32 || T is i8 || T is i16 || T is u8 || T is u16 || T is u32 {
		return json2.Any(input)
	} $else {
		$compile_error('JSON adapters require JSON-native output types')
	}
}

pub fn string() Schema {
	return from_schema(schemas.string())
}

pub fn number() Schema {
	return from_schema(schemas.number())
}

pub fn boolean() Schema {
	return from_schema(schemas.boolean())
}

pub fn unknown() Schema {
	return Schema{
		type_name: 'unknown'
		expects:   'unknown'
		run:       fn (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			return types.Dataset[json2.Any]{
				value: input
			}
		}
	}
}

pub fn any_value() Schema {
	return Schema{
		...unknown()
		type_name: 'any'
		expects:   'any'
	}
}

pub fn never() Schema {
	return Schema{
		type_name: 'never'
		expects:   'never'
		run:       fn (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			return type_issue('never', input, 'never')
		}
	}
}

pub fn null_value() Schema {
	return Schema{
		type_name: 'null'
		expects:   'null'
		run:       fn (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			if input is json2.Null { return types.Dataset[json2.Any]{
					value: input
				} }
			return type_issue('null', input, 'null')
		}
	}
}

pub fn literal(value json2.Any) Schema {
	return Schema{
		type_name: 'literal'
		expects:   diagnostics.issue_value(value)
		run:       fn [value] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			if equal(input, value) { return types.Dataset[json2.Any]{
					value: input
				} }
			return type_issue('literal', input, diagnostics.issue_value(value))
		}
	}
}

pub fn picklist(values []json2.Any) Schema {
	items := values.clone()
	return Schema{
		type_name: 'picklist'
		expects:   diagnostics.joined_values(items)
		run:       fn [items] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			for item in items {
				if equal(input, item) { return types.Dataset[json2.Any]{
						value: input
					} }
			}
			return type_issue('picklist', input, diagnostics.joined_values(items))
		}
	}
}

pub fn custom(predicate fn (json2.Any) bool) Schema {
	return Schema{
		type_name: 'custom'
		expects:   'unknown'
		run:       fn [predicate] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			if predicate(input) { return types.Dataset[json2.Any]{
					value: input
				} }
			return type_issue('custom', input, 'unknown')
		}
	}
}

pub fn equal(a json2.Any, b json2.Any) bool {
	if types.is_json_number(a) && types.is_json_number(b) {
		// Recursive JSON equality keeps NaN unequal; membership equality accepts it.
		if (a is f32 || a is f64) && math.is_nan(a.f64()) { return false }
		return types.native_set_equal[json2.Any](a, b)
	}
	if a is map[string]json2.Any && b is map[string]json2.Any {
		if a.len != b.len { return false }
		for key, value in a {
			other := b[key] or { return false }
			if !equal(value, other) { return false }
		}
		return true
	}
	if a is []json2.Any && b is []json2.Any {
		if a.len != b.len { return false }
		for i, value in a {
			if !equal(value, b[i]) { return false }
		}
		return true
	}
	return a == b
}

fn object_data(input json2.Any) !map[string]json2.Any {
	if input is map[string]json2.Any { return input }
	return error('Expected object')
}

// Validation failures are ordinary results; execution exceptions are returned.
pub fn safe_parse_checked(schema Schema, input json2.Any, configs ...types.Config) !types.SafeParseResult[json2.Any] {
	return methods.safe_parse_checked[json2.Any, json2.Any](native(schema), input, ...configs)
}

pub fn parse_with_config(schema Schema, input json2.Any, config types.Config) !json2.Any {
	return methods.parse_with_config[json2.Any, json2.Any](native(schema), input, config)
}

fn run_json(schema Schema, input json2.Any, config types.Config) types.Dataset[json2.Any] {
	return types.run[json2.Any, json2.Any](native(schema), input, config)
}

fn absent_json_default(config types.Config) json2.Any {
	_ = config
	return json2.Null{}
}

fn boxed_json_value(raw types.NativeValue) !json2.Any {
	if types.value_is[json2.Any](raw) { return types.value_as[json2.Any](raw) }
	if types.value_is[string](raw) { return json2.Any(types.value_as[string](raw)!) }
	if types.value_is[bool](raw) { return json2.Any(types.value_as[bool](raw)!) }
	if types.value_is[f64](raw) { return json2.Any(types.value_as[f64](raw)!) }
	return error('Value is outside the native JSON representation')
}
