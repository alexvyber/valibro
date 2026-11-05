module main

import os

struct Guide {
	slug    string
	title   string
	summary string
}

fn api_guides() []Guide {
	return [
		Guide{'schemas', 'Schemas and native values', 'Choose primitive schemas, literals, unions, and lazy schemas.'},
		Guide{'strings', 'Strings and formats', 'Validate string lengths, content, formats, and native regex.'},
		Guide{'numbers', 'Numbers and bounds', 'Validate numeric types, bounds, membership, and exact conversions.'},
		Guide{'transforms', 'Transformations', 'Compose same-type actions and transformations that change output types.'},
		Guide{'collections', 'Collections', 'Validate arrays, maps, ordered sets, and custom-key entry maps.'},
		Guide{'objects', 'Typed objects', 'Describe native struct fields with explicit getters and setters.'},
		Guide{'presence', 'Presence and defaults', 'Distinguish missing, undefined, null, and present values.'},
		Guide{'execution', 'Parsing and pipelines', 'Execute reusable schemas and understand output and abort behavior.'},
		Guide{'errors', 'Errors and issue paths', 'Inspect validation issues, paths, partial outputs, and runtime errors.'},
		Guide{'configuration', 'Configuration and messages', 'Scope messages, languages, and validation settings to a context.'},
		Guide{'metadata', 'Metadata and brands', 'Attach titles, descriptions, examples, metadata, and marker types.'},
		Guide{'custom', 'Custom validation', 'Write predicates, cross-field checks, and dataset-aware actions.'},
		Guide{'async', 'Async and functions', 'Use channels, reusable futures, and validated function contracts.'},
		Guide{'cache', 'Caching', 'Select cache keys, bounds, expiry, and inspect cache entries.'},
		Guide{'json', 'Runtime JSON schemas', 'Validate unknown JSON shapes, tuples, unions, and discriminated variants.'},
		Guide{'json-config', 'JSON parsing and serialization', 'Configure native JSON number handling, callbacks, and serialization.'},
		Guide{'unicode', 'Unicode', 'Normalize text and count code points, graphemes, and words.'},
		Guide{'types', 'Types and lower-level APIs', 'Work with datasets, native values, providers, and implementation modules.'},
		Guide{'native-behavior', 'Native behavior', 'Understand the V contracts for regex, URLs, dates, and numeric precision.'},
	]
}

fn symbol_guide(item ApiSymbol, inventory []ApiSymbol) string {
	match item.module_name {
		'json' { return 'json' }
		'jsoncodec' { return 'json-config' }
		'unicode' { return 'unicode' }
		'storages' { return 'configuration' }
		'types' { return 'types' }
		else {}
	}

	if item.kind != 'function' { return 'types' }
	if item.module_name == 'valibro' {
		for other in inventory {
			if other.name == item.name && other.receiver == ''
				&& other.module_name in ['actions', 'schemas', 'methods'] {
				return symbol_guide(other, inventory)
			}
		}
	}
	file := os.base(item.file)
	if file.contains('metadata') || item.name.starts_with('get_title')
		|| item.name.starts_with('get_description') || item.name.starts_with('get_examples')
		|| item.name.starts_with('get_metadata') {
		return 'metadata'
	}
	if file.contains('cache') { return 'cache' }
	if file.contains('function') || file == 'async.v' || item.name.contains('async')
		|| item.name.contains('promise') || item.name.contains('await') {
		return 'async'
	}
	if file.contains('messages') || item.name.contains('global_')
		|| item.name.contains('schema_message') || item.name.contains('specific_message')
		|| item.name == 'config' || item.name == 'message_fn' || item.name == 'message' {
		return 'configuration'
	}
	if file.contains('optional') || file == 'defaults.v' || item.name.starts_with('fallback') {
		return 'presence'
	}
	if file.contains('errors')
		|| item.name in ['get_dot_path', 'flatten', 'summarize', 'is_vali_error'] {
		return 'errors'
	}
	if file == 'struct.v' || item.name in ['field', 'object', 'object_from'] { return 'objects' }
	if file.contains('collection') || file.contains('array') || file.contains('entry_map')
		|| file in ['map.v', 'record.v', 'set.v'] {
		return 'collections'
	}
	if file.contains('numeric') || file.contains('value_checks')
		|| file.contains('value_transforms') || file in ['number.v', 'nan.v', 'bigint.v', 'date.v'] {
		return 'numbers'
	}
	if file.contains('conversion') || file.contains('string_transforms') { return 'transforms' }
	if file == 'json.v' || file.contains('stringify') { return 'json-config' }
	if file.contains('unicode') { return 'unicode' }
	if file.contains('format') || file.contains('string_checks')
		|| file.contains('string_measurements') || file == 'regex.v' {
		return 'strings'
	}
	if file == 'custom.v' || file == 'partial_check.v' || file == 'validation.v' { return 'custom' }
	if item.module_name == 'schemas' || file == 'api_schema.v' { return 'schemas' }
	if item.module_name == 'methods' || file == 'api_execution.v' { return 'execution' }
	if file == 'api_metadata.v' { return 'metadata' }
	if file == 'api_presence.v' { return 'presence' }
	if file == 'api_collections.v' { return 'collections' }
	if file == 'api_checks.v' { return 'strings' }
	if file == 'api_transform.v' { return 'transforms' }
	return 'types'
}

fn reference_page(item ApiSymbol, inventory []ApiSymbol, authored []Page, extra []string) !Page {
	guide := symbol_guide(item, inventory)
	import_name := if item.module_name == 'valibro' {
		'valibro as v'
	} else {
		'valibro.${item.module_name}'
	}
	summary := symbol_summary(item)
	if summary == '' { return error('Missing semantic description: ${item.id()}') }
	mut source := '# ${item.label()}\n\n${summary}\n\n## Signature\n\n```v signature\n${item.declaration}\n```\n\nImport `${import_name}`.\n\n'
	example := reference_example(item, authored, extra)
	if example != '' {
		source += '## Example\n\n'
		if item.module_name in ['actions', 'schemas', 'methods', 'storages']
			&& example.contains('import valibro as v') {
			source += 'This example uses the root convenience API for this implementation.\n\n'
		}
		source += '```v\n${example.trim_right('\n')}\n```\n\n'
	}
	source += 'See [${guide_title(guide)}](/guides/${guide}/) for usage patterns and related examples.\n\n'
	notes := accurate_notes(item)
	if notes != '' { source += '## Behavior\n\n${notes}\n\n' }
	if item.comment != '' {
		source += '## Source notes\n\n```text\n${item.comment.replace('```', '~~~')}\n```\n\n'
	}
	source += '## Related\n\n- [${item.module_name} module](${module_url(item.module_name)}): all public declarations.\n- [Native behavior](/guides/native-behavior/): supported inputs and language differences.\n\nSource: `${item.file}:${item.line}`.\n'
	return Page{
		url:         item.url()
		title:       item.label()
		section:     'Reference'
		file:        'site/reference.json (${item.id()})'
		summary:     summary
		api_id:      item.id()
		module_name: item.module_name
		category:    api_category(item, inventory)
		api_kind:    item.kind
		source:      source
		document:    markdown(source)!
	}
}

fn module_url(name string) string {
	return if name == 'valibro' { '/api/' } else { '/api/${name}/' }
}

fn guide_title(slug string) string {
	for guide in api_guides() {
		if guide.slug == slug { return guide.title }
	}
	return slug
}

fn symbol_summary(item ApiSymbol) string {
	if item.kind != 'function' && item.kind != 'method' {
		return type_description(item)
	}
	specific := specific_summary(item)
	if specific != '' { return specific }
	family := family_summary(item)
	if family != '' { return family }
	name := item.name
	descriptions := {
		'string':                 'Validate well-formed UTF-8 string input without trimming or normalization.'
		'number':                 'Validate a numeric input; reject NaN while permitting infinities unless another check excludes them.'
		'number_of':              'Validate a native numeric type while retaining its width and precision.'
		'boolean':                'Validate boolean input without implicit string or numeric conversion.'
		'bigint':                 'Validate a native arbitrary-precision integer.'
		'date':                   'Validate Gregorian calendar fields and the supported native date range.'
		'nan':                    'Accept only a floating NaN value.'
		'literal':                'Accept one specified literal value.'
		'picklist':               'Accept any value in a copied list of allowed requirements.'
		'enum_schema':            'Build a native enumeration schema from an explicit list of values.'
		'unknown':                'Preserve an input value without applying extra validation.'
		'any_value':              'Preserve an input value under the declared native input contract.'
		'never':                  'Reject every value of the declared input type.'
		'custom':                 'Validate input with a native predicate callback.'
		'check':                  'Add a predicate validation to an existing pipeline.'
		'guard':                  'Apply a same-type native predicate guard.'
		'raw_check':              'Create validation issues from a value through a native callback.'
		'raw_check_with_context': 'Inspect and return the current dataset with access to parsing configuration.'
		'partial_check':          'Run a cross-field predicate when its declared dependency paths are valid.'
		'array':                  'Validate and transform each item in an array.'
		'array_schema':           'Validate and transform each item in a native array.'
		'record':                 'Validate string keys and values in a native or JSON map.'
		'map_schema':             'Validate and transform native hash-map keys and values.'
		'set':                    'Validate and transform items in an insertion-ordered native set.'
		'set_with':               'Validate native set items using an explicit output equality callback.'
		'entry_map':              'Construct or validate an ordered entry map with explicit native key equality.'
		'object':                 'Build an object schema with native field mappings or explicit JSON entries.'
		'field':                  'Map one named native struct field through a schema and an explicit setter.'
		'object_from':            'Initialize a new native output struct and apply typed field mappings.'
		'strict_object':          'Validate declared JSON properties and reject unknown entries.'
		'loose_object':           'Validate declared JSON properties while retaining unknown entries.'
		'object_with_rest':       'Validate unknown JSON object properties through a rest schema.'
		'pick':                   'Select a subset of a runtime JSON object schema’s fields.'
		'omit':                   'Remove selected fields from a runtime JSON object schema.'
		'partial':                'Make selected or all runtime JSON object fields optional.'
		'required':               'Require selected or all runtime JSON object fields.'
		'keyof':                  'Build a picklist of a runtime JSON object schema’s keys.'
		'tuple':                  'Validate a JSON array through positional item schemas.'
		'strict_tuple':           'Validate positional items and reject additional JSON array entries.'
		'loose_tuple':            'Validate positional items while retaining additional JSON array entries.'
		'tuple_with_rest':        'Validate positional items and apply a rest schema to additional entries.'
		'union':                  'Accept an input through one of the supplied schema alternatives.'
		'intersect':              'Combine compatible outputs from multiple runtime JSON schemas.'
		'variant':                'Select a runtime JSON schema using a discriminator property.'
		'lazy':                   'Defer constructing a schema until execution.'
		'lazy_with':              'Select a deferred schema using the current input value.'
		'finite':                 'Require a finite floating value.'
		'integer':                'Require a finite floating value without a fractional part.'
		'safe_integer':           'Require an integer within the exact binary64 safe-integer range.'
		'multiple_of':            'Require an exact native zero remainder, without floating epsilon tolerance.'
		'gt_value':               'Require a value strictly greater than a bound.'
		'lt_value':               'Require a value strictly less than a bound.'
		'value':                  'Accept one required value while retaining the native type.'
		'values':                 'Accept membership in a copied requirement list.'
		'empty':                  'Require empty string input.'
		'non_empty':              'Require nonempty string input.'
		'starts_with':            'Require a literal string prefix.'
		'ends_with':              'Require a literal string suffix.'
		'includes':               'Require a literal string substring.'
		'excludes':               'Reject a literal string substring.'
		'regex':                  'Validate text with V’s native regex.pcre pattern syntax.'
		'regex_object':           'Validate text with a reusable compiled native regex.'
		'regex_with_flags':       'Validate text with an explicit native regex pattern and supported flags.'
		'compile_regex':          'Compile a native regex pattern and return errors for unsupported syntax or flags.'
		'url':                    'Require a valid absolute URI using the package’s native URL policy.'
		'normalize':              'Normalize Unicode text using the selected normalization form.'
		'word_count':             'Count default Unicode word segments containing a letter or number.'
		'word_boundaries':        'Return default Unicode word boundaries as rune indexes.'
		'grapheme_count':         'Count extended Unicode grapheme clusters.'
		'grapheme_boundaries':    'Return extended grapheme boundaries as rune indexes.'
		'is_emoji':               'Check the bundled emoji-sequence grammar.'
		'pipe':                   'Compose ordered actions that retain a schema’s output type.'
		'pipe_to':                'Compose a transformation that changes a schema’s output type.'
		'transform':              'Apply a native callback without changing the declared output type.'
		'transform_to':           'Apply a native callback with a different output type.'
		'is_valid':               'Return whether input validates, while retaining the parser’s runtime-error policy.'
		'assert_valid':           'Return a fallible error when input fails validation.'
		'flatten':                'Group issue messages into root, nested-path, and other errors.'
		'summarize':              'Format validation issues and available dot paths as readable text.'
		'get_dot_path':           'Format an issue path as a dot path where representable.'
		'forward':                'Attach action issues to the deepest existing prefix of a selected native path.'
		'safe_parse_async':       'Run validation on a V worker and deliver its result through a channel.'
		'parse_async':            'Run validation on a V worker and return a reusable native Future.'
		'parser_async':           'Create a reusable function that returns native futures.'
		'safe_parser_async':      'Create a reusable function that returns validation-result channels.'
		'await':                  'Resolve a native future, reusing the stored result on subsequent calls.'
		'function_schema':        'Validate a native function container.'
		'args':                   'Wrap a native function with input validation and transformation.'
		'returns':                'Wrap a native function with return-value validation and transformation.'
		'value_of':               'Box a native value for diagnostics and partial-output inspection.'
		'value_as':               'Recover an expected native value from a boxed view, returning an error on mismatch.'
		'value_is':               'Check the native type stored in a boxed value.'
		'some':                   'Construct an explicitly present native Maybe value.'
		'missing':                'Construct an explicitly missing native Maybe value.'
		'undefined_value':        'Construct an explicit undefined native Maybe value.'
		'null_value':             'Construct an explicit null value in the module’s native representation.'
		'decode':                 'Decode JSON text using native numeric alternatives and exact float rounding.'
		'stringify':              'Serialize a JSON value with explicit native formatting and callback configuration.'
	}
	if name in descriptions { return descriptions[name] }
	return format_summary(name)
}

fn module_page(name string, inventory []ApiSymbol) !Page {
	title := if name == 'valibro' { 'API reference' } else { name }
	summary := if name == 'valibro' {
		'Find a schema, compose a pipeline, or look up a native type.'
	} else {
		'Public declarations in the valibro.${name} module.'
	}
	members := inventory.filter(it.module_name == name)
	function_count := members.filter(it.kind in ['function', 'method']).len
	stats := '${function_count} functions and methods · ${members.len - function_count} types and constants'
	mut source := '# ${title}\n\n${summary}\n\n${stats}.\n\n'
	mut html := '<h1 id="${heading_id(title)}">${title}</h1><p>${escape(summary)}</p><div class="index-stats">${stats}</div>'
	groups := if name == 'valibro' { ['Schemas', 'Validation', 'Transformations', 'Execution',
			'JSON', 'Advanced', 'Types'] } else { ['Functions', 'Methods', 'Types'] }
	for group in groups {
		mut entries := []ApiSymbol{}
		for item in members {
			is_type := item.kind !in ['function', 'method']
			include := if group == 'Types' {
				is_type
			} else if name == 'valibro' {
				!is_type && api_category(item, inventory) == group
			} else if group == 'Functions' {
				item.kind == 'function'
			} else {
				item.kind == 'method'
			}
			if include { entries << item }
		}
		if entries.len == 0 { continue
		 }
		source += '## ${group}\n\n'
		html += '<section class="api-section"><h2 id="${heading_id(group)}">${group}<span class="item-count">${entries.len}</span></h2><div class="api-list">'
		for item in entries {
			description := symbol_summary(item)
			source += '- [${item.label()}](${item.url()}): ${description}\n'
			html += api_row(Page{
				url:         item.url()
				title:       item.label()
				summary:     description
				module_name: name
				api_kind:    item.kind
			})
		}
		source += '\n'
		html += '</div></section>'
	}
	document := markdown(source)!
	return Page{
		url:         module_url(name)
		title:       title
		section:     'Modules'
		file:        'site/reference.json'
		summary:     summary
		module_name: name
		category:    'Reference'
		source:      source
		document:    Markdown{
			...document
			html: html
		}
	}
}
