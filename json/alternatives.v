module json

import valibro.internal.diagnostics
import x.json2
import valibro.types
import valibro.schemas

pub fn union(options []Schema) Schema {
	return union_schema(options)
}

fn union_schema(options []Schema) Schema {
	mut native_options := []types.Schema[json2.Any, json2.Any]{}
	for option in options {
		native_options << native(option)
	}
	combined := schemas.union(native_options)
	return Schema{
		type_name: 'union'
		expects:   combined.expects
		items:     options.clone()
		run:       combined.run
	}
}

struct VariantLeaf {
	schema Schema
	keys   []string
}

fn variant_leaves(options []Schema, keys []string) []VariantLeaf {
	mut leaves := []VariantLeaf{}
	for option in options {
		if option.type_name == 'variant' {
			mut nested := keys.clone()
			if option.discriminator !in nested { nested << option.discriminator }
			leaves << variant_leaves(option.items, nested)
		} else {
			leaves << VariantLeaf{
				schema: option
				keys:   keys.clone()
			}
		}
	}
	return leaves
}

pub fn variant(key string, options []Schema) Schema {
	leaves := variant_leaves(options, [key])
	return Schema{
		type_name:     'variant'
		expects:       'Object'
		discriminator: key
		items:         options.clone()
		run:           fn [key, leaves] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			data := object_data(input) or { return type_issue('variant', input, 'object') }
			mut candidates := []types.Dataset[json2.Any]{}
			mut invalid_key := key
			mut priority := 0
			mut expected_discriminators := []string{}
			for leaf in leaves {
				mut valid := true
				for depth, discriminator_key in leaf.keys {
					discriminator := leaf.schema.entries[discriminator_key] or {
						panic('Variant option lacks discriminator ' + discriminator_key)
					}
					mut matches := discriminator.optional
					if tag := data[discriminator_key] {
						checked := run_json(discriminator, tag, types.Config{ abort_early: true })
						if exception := checked.exception { return types.Dataset[json2.Any]{
								typed:     false
								exception: exception
							} }
						matches = checked.typed && checked.issues.len == 0
					}
					if !matches {
						valid = false
						if invalid_key != discriminator_key && (depth > priority
							|| (depth == priority && discriminator_key in data
							&& invalid_key !in data)) {
							invalid_key = discriminator_key
							priority = depth
							expected_discriminators.clear()
						}
						if invalid_key == discriminator_key {
							expected_discriminators << discriminator.expects
						}

						break
					}
				}
				if !valid { continue
				 }
				result := run_json(leaf.schema, input, config)
				if exception := result.exception { return types.Dataset[json2.Any]{
						typed:     false
						exception: exception
					} }
				if result.typed && result.issues.len == 0 { return result }
				if candidates.len == 0 || (!candidates[0].typed && result.typed) { candidates = [
						result,
					] }
			}
			if candidates.len > 0 { return candidates[0] }
			return types.Dataset[json2.Any]{
				typed:  false
				value:  input
				issues: [
					types.Issue{
						...types.schema_type_issue('variant', types.DefaultMessage{},
							diagnostics.join_expects(expected_discriminators), if value := data[invalid_key] {
							diagnostics.issue_value(value)
						} else {
							'missing'
						}, 'type')
						path: [types.PathSegment(invalid_key)]
					},
				]
			}
		}
	}
}

pub fn lazy(getter fn () Schema) Schema {
	return Schema{
		type_name: 'lazy'
		run:       fn [getter] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			return getter().run(input, config)
		}
	}
}

pub fn intersect(options []Schema) Schema {
	items := options.clone()
	return Schema{
		type_name: 'intersect'
		expects:   join_intersection(items.map(it.expects))
		items:     items
		run:       fn [items] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			if items.len == 0 { return type_issue('intersect', input, 'never') }
			mut output := input
			mut outputs := []json2.Any{}
			mut issues := []types.Issue{}
			mut typed := true
			for item in items {
				result := run_json(item, input, config)
				if exception := result.exception { return types.Dataset[json2.Any]{
						typed:     false
						exception: exception
					} }
				issues << result.issues
				if config.abort_early && result.issues.len > 0 {
					typed = false
					break
				}
				typed = typed && result.typed
				if typed { outputs << result.value }
			}
			if typed {
				output = outputs[0]
				for value in outputs[1..] {
					output = merge(output, value) or {
						issues << types.schema_type_issue('intersect', types.DefaultMessage{},
							join_intersection(items.map(it.expects)), 'unknown', 'type')
						typed = false
						break
					}
				}
			}

			return types.Dataset[json2.Any]{
				typed:  typed
				value:  output
				issues: issues
			}
		}
	}
}

fn merge(a json2.Any, b json2.Any) !json2.Any {
	if equal(a, b) { return a }
	if a is map[string]json2.Any && b is map[string]json2.Any {
		mut output := a.clone()
		for key, value in b {
			if previous := output[key] {
				output[key] = merge(previous, value)!
			} else {
				output[key] = value
			}
		}
		return json2.Any(output)
	}
	if a is []json2.Any && b is []json2.Any && a.len == b.len {
		mut output := []json2.Any{}
		for i, item in a {
			output << merge(item, b[i])!
		}
		return json2.Any(output)
	}
	return error('Conflicting intersection outputs')
}

pub fn lazy_with(getter fn (json2.Any) Schema) Schema {
	return Schema{
		type_name: 'lazy'
		run:       fn [getter] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			return getter(input).run(input, config)
		}
	}
}

fn join_intersection(items []string) string {
	mut values := []string{}
	for item in items {
		if item !in values { values << item }
	}
	if values.len == 0 { return 'never' }
	if values.len == 1 { return values[0] }
	return '(' + values.join(' & ') + ')'
}
