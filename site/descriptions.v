module main

fn type_description(item ApiSymbol) string {
	if item.kind == 'const' && item.name == 'version' {
		return 'Unicode data version bundled with the normalization, casing, grapheme, word, and emoji algorithms.'
	}
	if item.module_name == 'json' && item.name == 'Schema' {
		return 'Runtime schema for x.json2.Any, retaining object entries, tuple items, alternatives, presence policies, and a validation runner for structural operations.'
	}
	if item.module_name == 'json' && item.name == 'ShapeRebuilder' {
		return 'Callback that rebuilds a runtime JSON object schema after its entry map changes, preserving the object mode used by pick, omit, partial, and required.'
	}
	if item.name == 'Regex' {
		return 'Alias of V’s compiled regex.pcre.Regex. Construct it with compile_regex; pass it to regex_object to reuse a native pattern.'
	}
	descriptions := {
		'ActionKind':             'Distinguishes validation, transformation, and metadata actions. Pipelines use this category to decide which actions may run after an issue.'
		'HashType':               'Selects the accepted hexadecimal digest width/algorithm for the hash string action; this does not compute a digest.'
		'IssueKind':              'Categorizes an issue as a schema, validation, or transformation failure, independently of its specific code.'
		'Presence':               'Four explicit input states: missing, undefined, null, and value. A zero-valued payload is not an absent value.'
		'Action':                 'Same-output-type pipeline step: its kind, annotations, optional contextual runner, and value callback determine validation or transformation behavior.'
		'Transformation':         'Type-changing pipeline step from I to O. Compose it with pipe_to; its dataset can hold transformed output, issues, or an exception.'
		'Schema':                 'Reusable native input/output contract Schema[I, O], with a configured dataset runner and optional presence, default, fallback, and annotation information.'
		'Dataset':                'Intermediate parser state containing the current value, typed flag, accumulated issues, optional boxed raw value, and runtime exception. A typed dataset can still have issues.'
		'SafeParseResult':        'Parse outcome with success-only optional output, structured issues, typed state, and boxed raw output. Async parsing can also return an exception in this container.'
		'Annotations':            'Optional title, description, string examples, and JSON metadata attached to a schema. These describe a value without validating it.'
		'Examples':               'Typed example values plus a present flag, distinguishing absent example metadata from an explicitly empty example list.'
		'Config':                 'Per-execution abort settings, language, optional override message, and scoped message maps. Supply it explicitly or bind it with config.'
		'Context':                'Caller-owned mutable store for validation configuration and scoped messages; setters do not mutate process-wide state.'
		'Messages':               'Language-indexed global, schema, and specific-code message maps carried through parsing configuration.'
		'ErrorMessage':           'Diagnostic value accepted by message-taking factories: a literal string, default-message marker, bare callback, or identified callback.'
		'DefaultMessage':         'Default diagnostic marker. Unlike an explicitly supplied custom message, it allows configured messages to override the fallback text.'
		'MessageFunction':        'Callback computing diagnostic text from a resolved Issue. Bare callbacks have no stable cache identity.'
		'MessageCallback':        'Message callback with a stable identity used in cache keys. Construct one with identified_message or message_fn.'
		'MessageProvider':        'Deferred issue-message callback used while resolving a dataset; active determines whether its getter participates.'
		'DefaultProvider':        'Typed computed-default callback with an availability flag, accepting the effective Config and returning a wrapped schema input.'
		'DefaultContextProvider': 'Computed-default callback that can inspect an optional input dataset and the effective Config.'
		'FallbackProvider':       'Computed replacement-output callback accepting an optional output dataset and Config; it is used after validation failures, not runtime exceptions.'
		'Maybe':                  'Native presence container pairing a Presence state with a payload T. Read the payload only for value state; use constructors to represent absence explicitly.'
		'Null':                   'Explicit native null marker accepted by null_schema. It is distinct from V’s none option state.'
		'Undefined':              'Explicit native undefined marker accepted by undefined_schema and void_schema; it is not an absent V variable.'
		'Symbol':                 'Native identity token with a descriptive label. Construct with types.symbol; equal descriptions do not make two tokens equal.'
		'Blob':                   'Native byte buffer with MIME metadata. count returns the byte length; JSON serialization exposes its declared fields.'
		'File':                   'Native byte buffer with MIME type, name, and last-modified metadata; no filesystem access is performed by this container.'
		'Set':                    'Insertion-ordered native values, normally constructed with new_set or new_set_with to apply deduplication and equality policy.'
		'MapEntry':               'One typed key/value pair in an ordered EntryMap, preserving keys that may not be usable in a native hash map.'
		'EntryMap':               'Insertion-ordered key/value entries constructed with an explicit key comparator. Collisions keep the original position and replace the value.'
		'NativeValue':            'Opaque GC-owned box retaining a native value and its type/equality information for partial output. Use value_of, value_is, and value_as instead of constructing its internals.'
		'RawArray':               'Mixed-type partial array output whose items are NativeValue boxes rather than a fabricated homogeneous success value.'
		'RawSet':                 'Mixed-type partial set output whose boxed items retain native equality and deduplication policy.'
		'RawEntry':               'Boxed native key/value pair used in mixed-type partial object and map outputs.'
		'RawMap':                 'Ordered boxed entries for a partial native map whose failed inputs and successful transformed outputs may have different types.'
		'RawObject':              'Boxed key/value entries for partial object output, retaining values that cannot fit a success-only typed result.'
		'RawStruct':              'Partial native struct view retaining its original typed value, ordered keys, and boxed field overrides.'
		'InvalidDate':            'Explicit marker for invalid date-conversion output. Its JSON value is null; it is not a malformed time.Time instance.'
		'ValidationError':        'Inspectable V error containing validation issues. parse returns it for ordinary validation failure; msg summarizes the issues.'
		'RangeError':             'Native runtime error for an invalid operation range, such as BigInt division by zero. Fallbacks do not swallow it.'
		'TypeError':              'Native runtime error for unsupported operations or incompatible value contracts, separate from an ordinary validation issue.'
		'Issue':                  'Structured diagnostic with code, category, resolved message, expected/received descriptions, and typed path metadata. UTF-16 accessors convert text on demand.'
		'PathSegment':            'Native issue-path component: a string object key/field name or an integer array index.'
		'Field':                  'Named native struct field mapping with a getter, output setter, and nested schema runner. field constructs it with all four native types intact.'
		'Branded':                'Value wrapper with a distinct compile-time marker type B. Read value explicitly when passing the underlying T to ordinary code.'
		'Flavored':               'Value wrapper carrying a compile-time marker type B and the underlying T; native V does not model TypeScript’s optional phantom properties.'
		'Function':               'Container for a native nonfallible callable. args and returns can wrap its call with validation and produce a fallible function.'
		'FallibleFunction':       'Container for a native callable returning !O, used after adding argument or return-value validation.'
		'Future':                 'Synchronized reusable result of worker parsing. Obtain it through parse_async or new_future, and resolve it with await.'
		'WrappedSchema':          'Opaque type-erased native schema with retained input/output signatures. Obtain it through wrap_schema; unwrap_schema verifies signatures before recovering it.'
		'PipelineRunner':         'Typed contextual dataset runner used by pipeline adapters to carry partial output, configuration, issues, and runtime exceptions across steps.'
		'CacheConfig':            'Bounded LRU policy: max_size, optional max_age_ms, and an injectable millisecond clock. Expiry is strictly after the age bound.'
		'CachedSchema':           'Wrapped schema plus synchronized LRU state and explicit key/get/set/clear operations. Obtain it with cached instead of constructing its private state.'
		'FlatErrors':             'Flattened diagnostics split into root messages, dot-path-indexed nested messages, and paths that cannot be represented as dot strings.'
		'ParseBooleanConfig':     'Explicit accepted truthy/falsy values for validated boolean parsing. Unknown values become issues rather than silently becoming false.'
		'ParseConfig':            'JSON parse configuration selecting optional binary64 projection and a fallible, presence-aware reviver with source/holder context.'
		'ParseJsonConfig':        'Root alias of jsoncodec.ParseConfig: binary64 projection and a presence-aware JSON reviver.'
		'StringifyConfig':        'JSON serialization policy for replacers, property selection, indentation, optional binary64 projection, and an explicit traversal-depth limit.'
		'StringifyJsonConfig':    'Root alias of jsoncodec.StringifyConfig, controlling replacers, selected properties, indentation, numeric projection, and depth.'
		'ReviverContext':         'Native snapshot supplied to a JSON reviver: optional original primitive source text and its containing object or array.'
		'JsonReviverContext':     'Root alias of jsoncodec.ReviverContext, containing primitive source text when available and a native holder snapshot.'
		'ReplacerContext':        'Native snapshot of the containing object/array supplied to a contextual JSON replacer before the replacement is applied.'
		'JsonReplacerContext':    'Root alias of jsoncodec.ReplacerContext, carrying the native containing object/array snapshot.'
		'Reviver':                'Fallible parse callback receiving key, decoded value, and source/holder context; its Maybe result can retain, replace, or remove a value.'
		'Replacer':               'Fallible serialization callback receiving a property key and JSON value; its Maybe result controls replacement or omission.'
		'ContextReplacer':        'Serialization replacer with a native holder snapshot, used when no presence-aware replacer is configured.'
		'PresenceReplacer':       'Highest-priority serialization replacer, able to inspect and replace missing/undefined/null/value states explicitly.'
		'Indent':                 'JSON indentation specified as a native integer width or literal string; widths are not clipped to JavaScript’s ten-character limit.'
		'JsonSourceHook':         'Fallible native serialization hook producing a presence-aware JSON value for a property key.'
		'JsonSource':             'Native serialization tree retaining explicit hooks, missing state, projected value, and child sources until traversal.'
		'UndefinedOutput':        'Error indicating that serialization omitted the root instead of producing JSON text.'
		'NormalizeForm':          'Unicode canonical/com-patibility normalization choice: NFC, NFD, NFKC, or NFKD. Normalization is independent of locale.'
		'SetEquality':            'Typed set-item equality callback used when deduplicating native values; keep input and transformed-output equality policies distinct.'
		'Countable':              'Native size contract exposing count() int, implemented by sets, entry maps, blobs, files, and custom countable values.'
		'NativeMaybe':            'Internal integration protocol exposing presence state for generic adapters. It is not a user-defined numeric/string coercion hook.'
		'FunctionValue':          'Internal marker distinguishing native function containers during boxing and serialization; it does not execute the callable.'
		'JsonValueProvider':      'Explicit fallible native JSON hook returning a Maybe JSON value for a property key. Return undefined to omit, null for a JSON null, or a value to serialize.'
		'NumberProvider':         'Native conversion contract to_number() !f64. Return the target floating value directly; an error becomes a conversion failure.'
		'BigintProvider':         'Native conversion contract to_bigint() !big.Integer, retaining arbitrary integer precision without an intermediate float.'
		'BooleanProvider':        'Native conversion contract to_boolean() !bool, required for custom values without a supported native boolean conversion.'
		'DateProvider':           'Native conversion contract to_date() !time.Time. Returned calendar fields are validated and nanoseconds remain native.'
		'StringProvider':         'Native conversion contract to_string() !string, returning explicit text instead of an implicit JavaScript primitive hint.'
	}
	return descriptions[item.name] or { '' }
}

fn family_summary(item ApiSymbol) string {
	name := item.name
	for suffix in ['_with_default_context', '_with_default_state', '_with_default', ''] {
		base := name.trim_string_right(suffix)
		states := {
			'optional':       'missing or undefined'
			'exact_optional': 'missing, but not explicit undefined'
			'nullable':       'null'
			'nullish':        'missing, undefined, or null'
			'undefinedable':  'undefined, but not missing'
		}
		if base in states {
			if item.module_name == 'json' {
				return 'Wrap a runtime JSON schema with the ${base} property-presence policy; explicit null handling differs from an absent object entry.'
			}
			callback := match suffix {
				'_with_default_context' { ' A computed default receives the optional input dataset and Config, then runs through the wrapped schema.' }
				'_with_default_state' { ' A computed default returns Maybe[I] from the optional dataset and Config, allowing an explicit absence state.' }
				'_with_default' { ' Compute the default input from Config, then validate and transform it through the wrapped schema.' }
				else { ' An optional default is an input to the wrapped schema; without one, the accepted absence state is preserved.' }
			}

			return
				'Accept ${states[base]} in Maybe input, as well as present values validated by the wrapped schema.' +
				callback
		}
	}
	if name in ['non_optional', 'non_nullable', 'non_nullish'] {
		rejected := if name == 'non_optional' {
			'missing and undefined'
		} else if name == 'non_nullable' {
			'null'
		} else {
			'missing, undefined, and null'
		}
		return 'Reject ${rejected} states before validating through the supplied presence wrapper.'
	}
	mut measurement := name
	mut comparison := 'equal to'
	for prefix in ['min_', 'max_', 'not_'] {
		if name.starts_with(prefix) {
			measurement = name[prefix.len..]
			comparison = if prefix == 'min_' {
				'at least'
			} else if prefix == 'max_' {
				'at most'
			} else {
				'different from'
			}
			break
		}
	}
	units := {
		'length':      'string Unicode code-point count'
		'length_of':   'native collection length (strings count Unicode code points)'
		'bytes':       'UTF-8 byte count'
		'code_points': 'Unicode scalar-value count'
		'graphemes':   'extended Unicode grapheme-cluster count'
		'words':       'default Unicode word count, excluding segments without letters or numbers'
		'entries':     'entry count (declared fields for structs, native length/count for other supported values)'
		'size':        'native size/count (including byte length for blobs and files)'
		'value':       'native value'
	}
	if measurement in units {
		return 'Require the ${units[measurement]} to be ${comparison} the supplied requirement; preserve the input on success.'
	}
	base := name.trim_string_right('_with_array')
	callbacks := {
		'map_items':    'Transform each array item, producing an array of the callback’s output type. The callback receives the item and its original index.'
		'filter_items': 'Keep array items whose predicate is true, preserving order and using original input indexes.'
		'find_item':    'Return the first matching item as types.some; return an undefined Maybe state when no item matches, including an empty array.'
		'reduce_items': 'Fold items left-to-right from the supplied initial accumulator, passing accumulator, item, and original index to the callback.'
		'every_item':   'Require every item to satisfy a predicate, stopping on the first failure; an empty array succeeds.'
		'some_item':    'Require at least one item to satisfy a predicate, stopping on the first match; an empty array fails.'
		'check_items':  'Check every item and collect a separate indexed issue for each failing predicate, rather than one array-level issue.'
	}
	if base in callbacks { return callbacks[base] + if name.ends_with('_with_array') {
			' The callback also receives the original complete array.'
		} else {
			''
		}
	 }
	conversion := name.trim_string_right('_from')
	conversions := {
		'to_number':     'Convert supported native input or numeric text to binary64, using exact ties-to-even rounding for decimal/radix text. Empty text and unsupported containers fail.'
		'to_bigint':     'Convert supported integer input or integer text to an arbitrary-precision integer; fractional values and unsupported containers fail.'
		'to_boolean':    'Convert using native boolean policy: string.bool() for text and nonzero/nonempty checks for supported numeric/countable input. Unsupported custom types require a BooleanProvider.'
		'to_date':       'Convert strict ISO text or supported epoch-millisecond input to a validated native time.Time, preserving integer milliseconds and provider nanoseconds.'
		'to_string':     'Convert an explicitly typed native input to text, retaining its native formatting rather than JavaScript array/object coercion.'
		'parse_boolean': 'Validate a recognized native boolean spelling or supported scalar; reject unrecognized values instead of silently returning false.'
	}
	if conversion in conversions { return conversions[conversion] }
	return ''
}

fn specific_summary(item ApiSymbol) string {
	name := item.name
	if item.kind == 'method' {
		if name.ends_with('.from') {
			return 'Convert a supported string or integer representation to this enum, returning an error when it does not identify a declared member.'
		}
		match name {
			'count' {
				return if item.receiver in ['Blob', 'File'] {
					'Return the byte length of the stored data without inspecting MIME metadata or touching the filesystem.'
				} else if item.receiver.starts_with('EntryMap') {
					'Return the number of stored key/value entries.'
				} else {
					'Return the number of stored set values.'
				}
			}
			'get' {
				return 'Look up a cached Dataset by its complete cache key, updating its LRU position; return none for absent or expired entries.'
			}
			'set' {
				return 'Store a Dataset under a complete cache key, update its timestamp/LRU position, and evict the oldest entry when capacity is exceeded.'
			}
			'key' {
				return 'Build the complete cache key from the caller-supplied input key function and Config; use the same Config as the parse call.'
			}
			'clear' {
				return 'Remove every dataset, timestamp, and LRU entry from this synchronized cache.'
			}
			'msg' {
				return if item.receiver == 'ValidationError' {
					'Join stored issue messages with semicolons for the V error message; this does not format issue paths.'
				} else {
					'Return the runtime error’s stored message text.'
				}
			}
			'code' {
				return 'Return V error code 1 for this error type; this is distinct from an Issue.code string.'
			}
			'message_units' {
				return 'Encode the resolved issue message as UTF-16 code units on demand, leaving the stored UTF-8 message unchanged.'
			}
			'received_units' {
				return 'Encode the issue’s received-value description as UTF-16 code units on demand.'
			}
			'maybe_state' {
				return 'Return this Maybe container’s explicit Presence state without reading its payload.'
			}
			'cache_identity' {
				return 'Return the stable message-callback identity assigned at construction; copied callbacks keep the same identity.'
			}
			'function_value' {
				return 'Mark this native callable container for generic function-value detection; this does not call the function.'
			}
			'to_json_value' {
				return if item.receiver == 'InvalidDate' {
					'Project the explicit invalid-date marker to JSON null.'
				} else {
					'Reject implicit JSON encoding of this function or future container; provide an explicit JSON hook or resolve the future first.'
				}
			}
			else {}
		}
	}
	if item.module_name == 'types' {
		if name == 'entry_map' {
			return 'Construct an insertion-ordered native entry map with an explicit key comparator; duplicate keys keep the first position and last value.'
		}
		if name == 'symbol' {
			return 'Create a fresh native identity token with the supplied description; repeated descriptions still create distinct symbols.'
		}
		if name == 'null_value' {
			return 'Construct Maybe[T] in null state without treating T’s zero value as a payload.'
		}
	}
	if item.module_name == 'json' {
		match name {
			'null_value' { return 'Build a runtime JSON schema accepting only explicit JSON null; a missing object entry is a different state.' }
			'object' { return 'Validate declared JSON object entries and strip unknown properties from successful output.' }
			'tuple' { return 'Validate positional JSON array items and discard extra items; use strict_tuple to reject extras or loose_tuple to retain them.' }
			'unwrap' { return 'Return the directly wrapped runtime JSON schema when present, otherwise return the supplied schema unchanged.' }
			'get_default' { return 'Return the runtime JSON schema’s configured/computed default, using the supplied Config when a provider exists.' }
			'get_fallback' { return 'Return the runtime JSON schema’s stored fallback output, or none when it has no literal fallback.' }
			'get_defaults' { return 'Recursively project JSON defaults from the schema’s entries/items; leaf schemas without defaults project to null.' }
			'get_fallbacks' { return 'Recursively project stored JSON fallback outputs from object/tuple structure, using null for leaves without fallback values.' }
			else {}
		}
	}
	if item.module_name == 'jsoncodec' && name == 'parse' {
		return 'Decode JSON text and run the configured reviver, returning a Maybe JSON value so a removed root is distinguishable from JSON null.'
	}
	if item.module_name == 'unicode' && name in ['to_lower', 'to_upper'] {
		return 'Apply full Unicode default ${name.all_after('to_')}case mapping to UTF-8 text, including expansions and contextual mapping; no locale tailoring is applied.'
	}
	if name == 'symbol' {
		return 'Build a schema accepting native types.Symbol tokens; this factory does not create a fresh symbol identity.'
	}
	if name == 'to_string' {
		return 'Return an identity action for native strings. It does not convert other types; use to_string_from[T] for that.'
	}
	if name in ['finite_of', 'integer_of', 'safe_integer_of'] {
		return match name {
			'finite_of' { 'Require a finite native numeric T; integer types are already finite and floating types reject infinities and NaN.' }
			'integer_of' { 'Require a whole native numeric T; integer types pass and floating types must be finite with no fractional part.' }
			else { 'Check the inclusive binary64 safe-integer range on native T without first rounding wide integers to f64.' }
		}
	}
	if (name.starts_with('get_') && name.contains('message'))
		|| (name.starts_with('set_') && name.contains('message'))
		|| (name.starts_with('delete_') && name.contains('message')) {
		action := if name.starts_with('get_') {
			'Read'
		} else if name.starts_with('set_') {
			'Set'
		} else {
			'Delete'
		}
		scope := if name.contains('specific') {
			'specific issue-code'
		} else if name.contains('schema') {
			'schema-kind'
		} else {
			'global fallback'
		}
		return '${action} a ${scope} diagnostic for the optional language key on the supplied Context, without changing process-global state.'
	}
	descriptions := {
		'emoji':                            'Validate an emoji sequence against the bundled Unicode property-based grammar, without treating every symbol or non-ASCII character as emoji.'
		'safe_parse':                       'Execute a schema and return success, typed state, issues, and success-only optional output; runtime exceptions panic instead of being returned as validation issues.'
		'config':                           'Bind an exact Config to a schema; this wrapper ignores config supplied later by a parse call rather than merging the two.'
		'set_global_config':                'Replace the configuration stored in the caller-owned mutable Context.'
		'get_global_config':                'Read the Config stored in the supplied Context.'
		'delete_global_config':             'Reset the supplied Context to an empty default Config.'
		'empty_of':                         'Require a zero native length/size for a supported string or countable value.'
		'non_empty_of':                     'Require a nonzero native length/size for a supported string or countable value.'
		'not_values':                       'Reject any member of a copied requirement list, using native equality (including NaN membership); an empty exclusion list accepts all values.'
		'null_schema':                      'Accept the explicit types.Null native marker, not V’s none option state.'
		'undefined_schema':                 'Accept the explicit types.Undefined native marker.'
		'void_schema':                      'Accept types.Undefined under a void schema name; it does not represent a V void return value.'
		'blob':                             'Build a schema for a native types.Blob container; it does not load data or infer a MIME type.'
		'file':                             'Build a schema for native types.File metadata/data, without reading a filesystem path.'
		'instance':                         'Preserve a statically typed native T; there is no runtime JavaScript constructor/prototype check.'
		'promise':                          'Build a schema for a native Future[T] container without awaiting its result.'
		'await_future':                     'Await a native Future[T] and produce T in a type-changing pipeline; resolution errors remain runtime exceptions.'
		'parse':                            'Execute a schema and return its output as !O; validation failures return ValidationError and runtime exceptions remain errors.'
		'parse_with_config':                'Execute a schema with explicit settings, returning output or a native validation/runtime error.'
		'parse_text':                       'Decode JSON text with jsoncodec.decode, then validate the decoded value through the runtime JSON schema.'
		'safe_parse_checked':               'Return structured validation issues while propagating runtime exceptions as V errors instead of panicking.'
		'safe_parse_with_config':           'Return structured validation results using explicit Config; runtime exceptions panic just as with safe_parse.'
		'safe_parse_async_with_config':     'Run checked parsing on a V worker with explicit Config, delivering validation output or a captured exception through a channel.'
		'parser':                           'Create a reusable native function that calls parse with this schema and returns !O.'
		'safe_parser':                      'Create a reusable function returning SafeParseResult; runtime exceptions still panic.'
		'pipe_from_actions':                'Compose a schema with an explicit action array, copying the array so later caller changes do not change the pipeline.'
		'raw_transform':                    'Create a same-type transformation from a callback returning Dataset[T], allowing explicit validation issues or runtime exceptions.'
		'raw_transform_to':                 'Create a type-changing transformation whose callback returns Dataset[O], preserving explicit issue/raw-output state.'
		'raw_transform_with_context':       'Transform a complete same-type dataset with access to the effective Config, retaining control of issues and raw output.'
		'raw_transform_to_with_context':    'Transform Dataset[I] into Dataset[O] with Config available, including explicit partial output and exception state.'
		'fallback':                         'Replace validation failures with a supplied output O without revalidating it; runtime exceptions propagate unchanged.'
		'fallback_fn':                      'Compute replacement output from the original input and its validation issues; the result is not revalidated and runtime exceptions are preserved.'
		'fallback_with_context':            'Compute replacement output from an optional failed output dataset and Config; the provider can also be inspected without a dataset.'
		'get_default':                      'Inspect a schema’s input default, evaluating its provider with empty dataset context; return none when no default exists.'
		'get_default_with_context':         'Evaluate a schema default with an explicitly supplied optional input dataset and Config, or return its stored literal default.'
		'get_fallback':                     'Inspect replacement output, invoking a contextual fallback provider without a dataset when one exists; plain fallback_fn is not an inspectable provider.'
		'get_fallback_with_context':        'Evaluate an inspectable fallback provider with an optional output dataset and Config, otherwise return the stored literal fallback.'
		'unwrap':                           'Recover the native schema directly inside a Maybe wrapper, panicking if no matching wrapped native signature exists.'
		'unwrap_as':                        'Recover a wrapped native schema only when its stored input/output signatures match the explicitly requested P and Q; otherwise return an error.'
		'entries_from_list':                'Construct a map assigning the supplied value/schema to every named key; duplicate keys collapse to one entry.'
		'entries_from_objects':             'Merge entry maps left-to-right; later maps replace values for duplicate keys.'
		'cache':                            'Wrap a schema in synchronized bounded LRU storage using an explicit native input-key callback and capacity.'
		'cache_with_config':                'Wrap a schema with an explicit LRU size, optional expiry age, clock, and caller-defined input identity.'
		'cached':                           'Construct an inspectable CachedSchema containing the wrapped schema, key builder, and synchronized get/set/clear operations.'
		'args':                             'Wrap a nonfallible native callable with argument validation, returning a FallibleFunction that validates and transforms input before calling it.'
		'returns':                          'Wrap a nonfallible native callable with result validation, returning a FallibleFunction whose output is the validated/transformed result.'
		'returns_checked':                  'Add return-value validation to an already-fallible callable, preserving errors from the original function.'
		'brand':                            'Transform a native string into Branded[string, B], retaining its value while adding a distinct marker type.'
		'brand_for':                        'Transform T into Branded[T, B], making the semantic marker explicit in the native output type.'
		'flavor':                           'Transform a native string into Flavored[string, B]; accessing the underlying string requires reading its value field.'
		'flavor_for':                       'Transform T into Flavored[T, B], retaining its value in a distinct native marker wrapper.'
		'readonly':                         'Return the same native string. V strings are already immutable; this action performs no runtime freezing.'
		'readonly_for':                     'Return the native T unchanged under V’s immutability rules, without recursively freezing reference-bearing values.'
		'title':                            'Attach a schema title without modifying validated string values.'
		'title_for':                        'Attach a title to a schema with native output type T.'
		'description':                      'Attach descriptive schema text without adding a validation rule.'
		'description_for':                  'Attach descriptive text to a schema with native output T.'
		'examples':                         'Attach copied string example metadata; these values are not executed as validation rules.'
		'examples_for':                     'Attach typed example metadata, retaining the difference between absent and explicitly empty examples.'
		'metadata':                         'Merge copied JSON metadata entries into a string schema’s annotations; later entries override matching keys.'
		'metadata_for':                     'Attach JSON metadata entries to a schema with output type T, merging keys through pipeline composition.'
		'get_title':                        'Read an optional schema title without evaluating its validation runner.'
		'get_description':                  'Read optional schema description metadata without parsing input.'
		'get_examples':                     'Read optional string example metadata stored on schema annotations.'
		'get_examples_for':                 'Read a copied typed example list, returning none when examples were never attached.'
		'get_metadata':                     'Return a copy of the schema’s metadata map so mutating map entries does not modify the stored annotation map.'
		'message':                          'Override only issues newly produced by the wrapped action, leaving pre-existing dataset issues unchanged.'
		'message_fn':                       'Construct an identified issue-message callback with stable cache identity; copies share the identity.'
		'schema_is_of_type':                'Compare a schema’s type_name with a supplied name; this is metadata introspection, not native type validation.'
		'action_is_of_type':                'Compare an action’s type_name with a supplied name.'
		'action_is_of_kind':                'Compare an action’s ActionKind category with a supplied enum member.'
		'is_of_type':                       'Compare an item’s type_name metadata with a string; this does not validate a value against the item.'
		'is_of_kind':                       'Compare an item’s kind string representation with the requested category.'
		'is_vali_error':                    'Test whether an IError is the package’s ValidationError type, distinguishing validation issues from runtime errors.'
		'sort_items':                       'Return a stable sorted copy of the input array using a negative/zero/positive native comparator; the caller’s input array is not sorted in place.'
		'includes_item':                    'Require an array item equal to the requirement under native membership equality.'
		'excludes_item':                    'Reject arrays containing an item equal to the requirement.'
		'mime_type':                        'Require blob/file MIME metadata to equal one of the allowed strings; this does not inspect the bytes or infer content type.'
		'hash':                             'Require hexadecimal digest text with one of the selected algorithm widths; no digest is computed or verified against source content.'
		'trim':                             'Remove native Unicode whitespace from both ends of a string, without changing interior whitespace.'
		'trim_start':                       'Remove native Unicode whitespace only from the beginning of a string.'
		'trim_end':                         'Remove native Unicode whitespace only from the end of a string.'
		'to_lower_case':                    'Apply full default Unicode lowercase mapping, including contextual final sigma; locale-specific casing is not selected.'
		'to_upper_case':                    'Apply full default Unicode uppercase mapping, including expansions such as Straße to STRASSE.'
		'to_camel_case':                    'Split case-style words and join them with a lowercase initial segment and capitalized subsequent segments.'
		'to_pascal_case':                   'Split case-style words and join them with capitalized initial and subsequent segments.'
		'to_kebab_case':                    'Split case-style words, lowercase them, and join with hyphens; this is not linguistic word segmentation.'
		'to_snake_case':                    'Split case-style words, lowercase them, and join with underscores.'
		'to_min_value':                     'Clamp values below an inclusive native lower bound up to the bound; values already above it are unchanged.'
		'to_max_value':                     'Clamp values above an inclusive native upper bound down to the bound; values already below it are unchanged.'
		'parse_boolean_with_config':        'Parse text using configured truthy/falsy spelling lists, rejecting unknown values.'
		'parse_boolean_with_values':        'Parse explicitly typed input using caller-supplied true/false requirement lists; unmatched values produce an issue.'
		'parse_json':                       'Decode native JSON text into x.json2.Any; invalid JSON becomes a transformation issue and float tokens use exact rounding.'
		'parse_json_with_config':           'Decode JSON with reviver configuration and return Maybe[Any], allowing the reviver to omit the root distinctly from null.'
		'stringify_json':                   'JSON-encode the input string as a quoted/escaped JSON string; it does not validate or format an existing JSON document.'
		'stringify_json_value':             'Project a typed native value to JSON and serialize it, applying supported native container and provider policies.'
		'stringify_json_value_with_config': 'Serialize typed native input with explicit replacer, indentation, property-list, numeric, and depth settings.'
		'stringify_json_with_config':       'Serialize x.json2.Any to UTF-8 JSON text with configured callbacks and formatting.'
		'stringify_json_with_config_utf16': 'Serialize x.json2.Any using configured policy, returning explicit UTF-16 units instead of ordinary UTF-8 output.'
		'stringify_utf16':                  'Serialize a JSON value and return UTF-16 code units explicitly, using the same formatting and callback configuration.'
		'stringify_source':                 'Serialize a JsonSource tree, applying its deferred native hooks as each property is traversed.'
		'from_schema':                      'Adapt a typed native schema to x.json2.Any, checking native input compatibility at runtime and projecting typed/partial output back to JSON.'
		'native':                           'Adapt a runtime JSON schema into Schema[Any, Any] for composition with native pipeline methods.'
		'equal':                            'Compare runtime JSON values recursively, preserving native integer precision; mixed integer/float values are equal only when their mathematical values match exactly. NaN remains unequal.'
		'required_with_message':            'Require selected or all runtime JSON object fields, attaching a diagnostic for required missing entries.'
	}
	return descriptions[name] or { helper_summary(item) }
}

fn helper_summary(item ApiSymbol) string {
	descriptions := {
		'apply_action':              'Apply an action to an existing dataset, preserving prior issues and honoring its contextual runner when configured.'
		'run':                       'Execute a Schema[I, O] with effective Config and resolve its dataset messages, retaining typed/raw output and runtime errors.'
		'run_action':                'Run a same-type action against a value with Config, creating the initial dataset for action execution.'
		'run_transformation':        'Execute a type-changing transformation with Config and resolve the returned dataset’s issue messages.'
		'contextual_action':         'Build an action whose callback receives Dataset[T] and Config, rather than only a value.'
		'contextual_transformation': 'Build a type-changing action from a Dataset[I]/Config callback producing Dataset[O].'
		'awaiting':                  'Construct a Transformation[Future[T], T] that awaits its input; failed resolution is retained as a dataset exception.'
		'new_future':                'Wrap a channel that will deliver a SafeParseResult into a synchronized reusable Future.'
		'identified_message':        'Wrap a message function in a fresh stable identity used to distinguish callback configurations in cache keys.'
		'is_json_number':            'Test whether a json2.Any value is one of its supported native numeric alternatives, without converting it.'
		'native_set_equal':          'Compare native values for membership: JSON integer precision is preserved, mixed integer/float values must match exactly, floating NaN equals NaN, and signed zeros compare equal.'
		'new_set':                   'Deduplicate a native list while preserving first-occurrence order; floating NaNs compare equal and signed zeros are normalized.'
		'new_set_with':              'Deduplicate a native list with an explicit comparator while preserving the first matching value’s position.'
		'raw_entry_set':             'Insert or replace a boxed key/value pair using native boxed equality, retaining the first key position on collision.'
		'raw_entry_set_with':        'Insert or replace boxed entries using the requested native key comparator where key types match, retaining failed values’ native identity.'
		'raw_set':                   'Deduplicate boxed native values using their retained equality information, normalizing supported floating signed zeros.'
		'raw_set_with':              'Deduplicate boxed values using an explicit comparator for the requested T while preserving other native types’ equality.'
		'new_issue':                 'Construct a validation issue from its code, literal message, and expected/received descriptions.'
		'issue_of_kind':             'Construct a categorized issue with an ErrorMessage, retaining deferred message callbacks for later config-aware resolution.'
		'schema_issue':              'Construct a schema-category diagnostic while retaining the supplied message policy and expected/received text.'
		'schema_type_issue':         'Construct a schema mismatch diagnostic with explicit native input-type labeling and message policy.'
		'resolve_message':           'Evaluate a literal/default/callback ErrorMessage against one Issue, without selecting a Context scope.'
		'resolve_issue':             'Resolve one issue’s effective message using factory overrides, Config, scoped messages, and the issue’s provider.'
		'resolve_dataset':           'Resolve diagnostic messages across a dataset using Config while retaining its value, typed/raw state, and exception.'
		'utf16_units':               'Encode UTF-8 text into UTF-16 units explicitly; ordinary diagnostics and JSON output remain UTF-8.'
		'utf16_display':             'Display UTF-16 units as text, combining valid surrogate pairs and escaping lone surrogate units instead of dropping them.'
		'wrap_schema':               'Erase a native schema’s concrete input/output types into WrappedSchema while retaining signatures for checked recovery.'
		'unwrap_schema':             'Recover the directly wrapped native schema only after checking requested input/output type signatures, returning an error on mismatch or absence.'
	}
	return descriptions[item.name] or { '' }
}

// Contract text is selected by API semantics, never by finding Schema/Action in
// a parameter list (parse and pipe accept those types but are not factories).
fn accurate_notes(item ApiSymbol) string {
	name := item.name
	if item.kind == 'typedef'
		&& name in ['MessageFunction', 'SetEquality', 'ShapeRebuilder', 'Reviver', 'Replacer', 'ContextReplacer', 'PresenceReplacer', 'JsonSourceHook'] {
		return 'Pass an ordinary native callback to a parameter typed with this alias, or return it from a function declaring this alias as its result. The executable example supplies the expected signature through that typed boundary.'
	}
	if name == 'entries_from_objects' && item.module_name != 'json' {
		return 'Later maps win on duplicate keys. When V cannot infer the element type in a nested expression, specify it explicitly, for example `entries_from_objects[int](first, second)`.'
	}
	if name == 'config' {
		return 'Binding is a replacement policy: parsing the configured schema with a different Config does not override the settings captured here. Configure an outer schema deliberately when composing wrappers.'
	}
	if item.module_name == 'json' && name == 'parse_text' {
		return 'Uses jsoncodec.decode and exact ties-to-even binary64 rounding for floats at every nesting depth. Dynamic integer-token representation still follows x.json2; use an explicit integer decoder or string/BigInt conversion when required. Validation failures and decoder/runtime errors propagate through the ! result.'
	}
	if name in ['parse', 'parse_with_config', 'assert_valid', 'parser', 'parse_text']
		&& item.module_name != 'jsoncodec' {
		return 'Ordinary invalid input produces ValidationError; callback/runtime exceptions propagate as native errors. Handle the ! result with or or error propagation. A configured schema can bind its own settings.'
	}
	if name in ['safe_parse', 'safe_parse_with_config', 'safe_parser', 'is_valid'] {
		return 'Validation failures are ordinary results, but runtime exceptions panic. Use safe_parse_checked to catch runtime errors. The typed flag is not a success flag; output is present only when validation succeeds.'
	}
	if name == 'safe_parse_checked' {
		return 'The V ! result carries runtime exceptions; a returned SafeParseResult carries ordinary validation failure. On failure its output is none and raw_output retains the applicable failure/partial value.'
	}
	if name in ['pipe', 'pipe_from_actions'] {
		return 'Actions execute in order on the schema’s output type. Consecutive checks can collect issues; a later transformation is skipped and ends the pipeline after an issue. Actions and annotations are copied so the original schema remains reusable.'
	}
	if name == 'pipe_to' {
		return 'The transformation runs only when the preceding dataset is typed and issue-free. Otherwise the result is untyped, retains the previous issues and boxed raw output, and does not invent a successful value of the new type.'
	}
	if name in ['unwrap', 'unwrap_as', 'unwrap_schema'] { return if item.module_name == 'json' {
			'This only removes one wrapped layer; it does not recursively simplify a runtime schema.'
		} else {
			'Recovery is one layer deep and verifies the native input/output signatures. unwrap panics on recovery errors; unwrap_as and unwrap_schema return them.'
		}
	 }
	if name in ['find_item', 'find_item_with_array'] {
		return 'No match is a successful transformation to Maybe with state undefined, not a validation issue and not missing. Inspect state before reading value.'
	}
	if name in ['every_item', 'every_item_with_array', 'some_item', 'some_item_with_array',
		'check_items', 'check_items_with_array'] {
		return 'every_item/some_item short-circuit and report an array-level issue. check_items visits all items and attaches one issue per failing original index. These callbacks preserve the input array.'
	}
	if name == 'sort_items' {
		return 'The comparator returns a negative value for before, zero for equal, and positive for after. Sorting uses a stable merge sort and returns a copy, including for empty/single-element arrays.'
	}
	if name in ['fallback', 'fallback_fn', 'fallback_with_context'] {
		return 'Replacement values are output O, not input I: they bypass validation/transformation of the wrapped schema. A failed runtime operation is not rescued. Inspection through get_fallback supports literal/contextual providers, not the input-and-issues callback of plain fallback_fn.'
	}
	if name in ['to_string', 'readonly', 'readonly_for'] {
		return 'This action returns its input unchanged. It does not perform conversion, runtime deep freezing, or recursive cloning. Use an explicit typed transformation when a different output is needed.'
	}
	if name in ['regex', 'regex_object', 'regex_with_flags', 'compile_regex'] {
		return 'Patterns and flags follow V regex.pcre, not JavaScript RegExp. The compile helper is fallible; pattern-taking action factories can panic on invalid syntax. The check does not maintain a JavaScript-style lastIndex.'
	}
	if name == 'to_boolean' {
		return 'The string action uses native string.bool(): unrecognized spellings produce false, not a validation issue. Use parse_boolean to reject unknown spellings.'
	}
	if name == 'to_number' || name == 'to_number_from' {
		return 'Conversion explicitly targets f64 and can round wide integer input. Decimal/radix text rounds once with ties to even; empty text, BOM-prefixed text, and unsupported arrays/maps fail. Use BigInt or native integer values when binary64 precision is insufficient.'
	}
	if name == 'to_date' || name == 'to_date_from' {
		return 'Text accepts strict ISO dates/date-times with four-digit years, UTC defaults, and explicit numeric offsets. Native integer epoch milliseconds and provider nanoseconds retain precision. Invalid conversion output is distinct from a valid time.Time.'
	}
	if name == 'multiple_of' {
		return 'Floating checks use native fmod without epsilon tolerance: 0.3 fails a 0.1 requirement. Zero/NaN divisors fail validation. BigInt division by zero is a runtime RangeError; use checked parsing to catch it.'
	}
	if name in ['word_count', 'word_boundaries', 'words', 'min_words', 'max_words', 'not_words'] {
		return 'Segmentation uses Unicode 17 default UAX #29 boundaries, with no locale/dictionary tailoring. Only segments containing a letter or number count as words. Boundary arrays contain rune indexes, not UTF-8 byte offsets.'
	}
	if name == 'entry_map' { return if item.module_name == 'types' {
			'The comparator belongs to input-key construction. Preserve it when building a schema that also transforms keys; an output comparator may require a different native type.'
		} else {
			'The comparator here applies to transformed output keys. Build input entries with types.entry_map and its input-key comparator. Collisions retain the first key position and the last value.'
		}
	 }
	if item.module_name == 'json' && name == 'object' {
		return 'Input must be a JSON object; arrays are rejected rather than converted to numeric-keyed objects. Missing entries are handled by each field’s optional/default/fallback policy. Unknown input properties are stripped; choose strict_object, loose_object, or object_with_rest for a different policy.'
	}
	if item.module_name == 'json'
		&& name in ['strict_object', 'loose_object', 'object_with_rest', 'record', 'variant'] {
		return 'Input must be a JSON object. Arrays, including empty arrays, are rejected at the object boundary; numeric-looking keys in actual objects remain ordinary string keys.'
	}
	if item.module_name == 'types' && item.name in ['NativeValue', 'WrappedSchema', 'Future'] {
		return 'Construct this value through its public factory. Its private storage cannot be safely initialized by copying the displayed declaration or supplying a nil pointer.'
	}
	return ''
}
