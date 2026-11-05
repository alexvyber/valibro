module jsoncodec

import x.json2
import valibro.types

// Holder is an immutable native snapshot of the containing object or array.
pub struct ReviverContext {
pub:
	source ?string
	holder json2.Any = json2.Null{}
}

pub type Reviver = fn (string, json2.Any, ReviverContext) !types.Maybe[json2.Any]

// Holder is the containing object/array before replacer substitution.
pub struct ReplacerContext {
pub:
	holder json2.Any = json2.Null{}
}

pub type ContextReplacer = fn (string, json2.Any, ReplacerContext) !types.Maybe[json2.Any]

// Presence-aware callbacks can replace undefined as well as ordinary JSON values.
pub type PresenceReplacer = fn (key string, value types.Maybe[json2.Any], context ReplacerContext) !types.Maybe[json2.Any]

pub type Replacer = fn (string, json2.Any) !types.Maybe[json2.Any]

pub type Indent = int | string

pub struct ParseConfig {
pub:
	binary64_numbers bool
	reviver          Reviver = fn (key string, value json2.Any, context ReviverContext) !types.Maybe[json2.Any] {
		return types.some[json2.Any](value)
	}
}

pub struct StringifyConfig {
pub:
	binary64_numbers bool
	replacer         Replacer = fn (key string, value json2.Any) !types.Maybe[json2.Any] {
		return types.some[json2.Any](value)
	}
	// Presence-aware replacers take precedence, followed by contextual replacers.
	replacer_with_presence ?PresenceReplacer
	replacer_with_context  ?ContextReplacer
	// None preserves native map iteration order; an empty list selects no properties.
	property_list ?[]string
	space         Indent
	// Zero means no explicit depth bound; traversal is iterative.
	max_depth int
}

// A native toJSON equivalent. Undefined omits a property; callback errors become issues.
pub interface JsonValueProvider {
	to_json_value(key string) !types.Maybe[json2.Any]
}
