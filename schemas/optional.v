module schemas

import valibro.types

fn maybe_schema[I, O](wrapped types.Schema[I, O], kind string, defaults []I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	assert defaults.len <= 1, 'Expected at most one default value'
	fallback := defaults.clone()
	expects := match kind {
		'exact_optional' { wrapped.expects }
		'nullable' { '(' + wrapped.expects + ' | null)' }
		'nullish' { '(' + wrapped.expects + ' | null | undefined)' }
		else { '(' + wrapped.expects + ' | undefined)' }
	}

	mut default_value := ?types.Maybe[I](none)
	if fallback.len > 0 { default_value = types.some(fallback[0]) }
	return types.Schema[types.Maybe[I], types.Maybe[O]]{
		wrapped_schema: types.wrap_schema(wrapped)
		type_name:      kind
		expects:        expects
		default_value:  default_value
		run:            fn [wrapped, kind, fallback] [I, O](input types.Maybe[I], config types.Config) types.Dataset[types.Maybe[O]] {
			allowed := match kind {
				'optional' { input.state in [.missing, .undefined] }
				'exact_optional' { input.state == .missing }
				'nullable' { input.state == .null }
				'undefinedable' { input.state == .undefined }
				'nullish' { input.state != .value }
				else { false }
			}

			if input.state == .value || (allowed && fallback.len > 0) {
				value := if input.state == .value { input.value } else { fallback[0] }
				result := types.run[I, O](wrapped, value, config)
				if exception := result.exception { return types.Dataset[types.Maybe[O]]{
						typed:     false
						exception: exception
					} }
				return types.Dataset[types.Maybe[O]]{
					raw_value: result.raw_value
					typed:     result.typed
					value:     types.some(result.value)
					issues:    result.issues
				}
			}
			if allowed { return types.Dataset[types.Maybe[O]]{
					value: types.Maybe[O]{
						state: input.state
					}
				} }
			return types.Dataset[types.Maybe[O]]{
				typed:  false
				value:  types.Maybe[O]{
					state: input.state
				}
				issues: [
					types.schema_type_issue(wrapped.type_name, wrapped.message or {
						types.DefaultMessage{}
					}, wrapped.expects, if input.state == .null { 'null' } else { 'undefined' },
						'type'),
				]
			}
		}
	}
}

pub fn optional[I, O](wrapped types.Schema[I, O], defaults ...I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_schema(wrapped, 'optional', defaults)
}

pub fn exact_optional[I, O](wrapped types.Schema[I, O], defaults ...I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_schema(wrapped, 'exact_optional', defaults)
}

pub fn nullable[I, O](wrapped types.Schema[I, O], defaults ...I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_schema(wrapped, 'nullable', defaults)
}

pub fn nullish[I, O](wrapped types.Schema[I, O], defaults ...I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_schema(wrapped, 'nullish', defaults)
}

pub fn non_optional[I, O](wrapped types.Schema[types.Maybe[I], types.Maybe[O]], messages ...types.ErrorMessage) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return non_presence(wrapped, 'non_optional', messages)
}

pub fn non_nullable[I, O](wrapped types.Schema[types.Maybe[I], types.Maybe[O]], messages ...types.ErrorMessage) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return non_presence(wrapped, 'non_nullable', messages)
}

pub fn non_nullish[I, O](wrapped types.Schema[types.Maybe[I], types.Maybe[O]], messages ...types.ErrorMessage) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return non_presence(wrapped, 'non_nullish', messages)
}

fn non_presence[I, O](wrapped types.Schema[types.Maybe[I], types.Maybe[O]], kind string, messages []types.ErrorMessage) types.Schema[types.Maybe[I], types.Maybe[O]] {
	expects := match kind {
		'non_optional' { '!undefined' }
		'non_nullable' { '!null' }
		else { '(!null & !undefined)' }
	}

	text := if messages.len > 0 { messages[0] } else { types.ErrorMessage(types.DefaultMessage{}) }
	return types.Schema[types.Maybe[I], types.Maybe[O]]{
		wrapped_schema: types.wrap_schema(wrapped)
		type_name:      kind
		expects:        expects
		message:        text
		run:            fn [wrapped, kind, expects, text] [I, O](input types.Maybe[I], config types.Config) types.Dataset[types.Maybe[O]] {
			rejected := match kind {
				'non_optional' { input.state in [.missing, .undefined] }
				'non_nullable' { input.state == .null }
				else { input.state != .value }
			}

			if rejected { return types.Dataset[types.Maybe[O]]{
					typed:  false
					value:  types.Maybe[O]{
						state: input.state
					}
					issues: [
						types.schema_type_issue(kind, text, expects, if input.state == .null {
							'null'
						} else {
							'undefined'
						}, 'type'),
					]
				}
			 }
			result := types.run[types.Maybe[I], types.Maybe[O]](wrapped, input, config)
			if result.exception != none { return result }
			output_rejected := match kind {
				'non_optional' { result.value.state in [.missing, .undefined] }
				'non_nullable' { result.value.state == .null }
				else { result.value.state != .value }
			}

			if output_rejected {
				mut issues := result.issues.clone()
				issues << types.schema_type_issue(kind, text, expects, if result.value.state == .null {
					'null'
				} else {
					'undefined'
				}, 'type')
				return types.Dataset[types.Maybe[O]]{
					typed:  false
					value:  result.value
					issues: issues
				}
			}
			return result
		}
	}
}

fn maybe_with_default[I, O](wrapped types.Schema[I, O], kind string, getter fn (types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	base := maybe_schema(wrapped, kind, []I{})
	provider := types.DefaultProvider[types.Maybe[I]]{
		available: true
		get:       fn [getter] [I, O](config types.Config) types.Maybe[I] {
			return types.some(getter(config))
		}
	}
	return types.Schema[types.Maybe[I], types.Maybe[O]]{
		...base
		default_provider: provider
		run:              fn [base, wrapped, getter, kind] [I, O](input types.Maybe[I], config types.Config) types.Dataset[types.Maybe[O]] {
			allowed := match kind {
				'optional' { input.state in [.missing, .undefined] }
				'exact_optional' { input.state == .missing }
				'nullable' { input.state == .null }
				'undefinedable' { input.state == .undefined }
				else { input.state != .value }
			}

			if allowed {
				result := types.run[I, O](wrapped, getter(config), config)
				if exception := result.exception { return types.Dataset[types.Maybe[O]]{
						typed:     false
						exception: exception
					} }
				return types.Dataset[types.Maybe[O]]{
					raw_value: result.raw_value
					typed:     result.typed
					value:     types.some(result.value)
					issues:    result.issues
				}
			}
			return types.run[types.Maybe[I], types.Maybe[O]](base, input, config)
		}
	}
}

pub fn optional_with_default[I, O](schema types.Schema[I, O], getter fn (types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_default(schema, 'optional', getter)
}

pub fn exact_optional_with_default[I, O](schema types.Schema[I, O], getter fn (types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_default(schema, 'exact_optional', getter)
}

pub fn nullable_with_default[I, O](schema types.Schema[I, O], getter fn (types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_default(schema, 'nullable', getter)
}

pub fn nullish_with_default[I, O](schema types.Schema[I, O], getter fn (types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_default(schema, 'nullish', getter)
}

pub fn undefinedable_with_default[I, O](schema types.Schema[I, O], getter fn (types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_default(schema, 'undefinedable', getter)
}

fn maybe_with_default_context[I, O](wrapped types.Schema[I, O], kind string, getter fn (?types.Dataset[types.Maybe[I]], types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	base := maybe_schema(wrapped, kind, []I{})
	return types.Schema[types.Maybe[I], types.Maybe[O]]{
		...base
		default_context_provider: types.DefaultContextProvider[types.Maybe[I]]{
			available: true
			get:       fn [getter] [I, O](dataset ?types.Dataset[types.Maybe[I]], config types.Config) types.Maybe[I] {
				return types.some(getter(dataset, config))
			}
		}
		run:                      fn [base, wrapped, kind, getter] [I, O](input types.Maybe[I], config types.Config) types.Dataset[types.Maybe[O]] {
			allowed := match kind {
				'optional' { input.state in [.missing, .undefined] }
				'exact_optional' { input.state == .missing }
				'nullable' { input.state == .null }
				'undefinedable' { input.state == .undefined }
				else { input.state != .value }
			}

			if !allowed { return types.run[types.Maybe[I], types.Maybe[O]](base, input, config) }
			value := getter(types.Dataset[types.Maybe[I]]{ typed: false, value: input }, config)
			result := types.run[I, O](wrapped, value, config)
			return types.Dataset[types.Maybe[O]]{
				raw_value: result.raw_value

				typed:     result.typed
				value:     types.some(result.value)
				issues:    result.issues
				exception: result.exception
			}
		}
	}
}

pub fn optional_with_default_context[I, O](schema types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_default_context(schema, 'optional', getter)
}

pub fn exact_optional_with_default_context[I, O](schema types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_default_context(schema, 'exact_optional', getter)
}

pub fn nullable_with_default_context[I, O](schema types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_default_context(schema, 'nullable', getter)
}

pub fn nullish_with_default_context[I, O](schema types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_default_context(schema, 'nullish', getter)
}

pub fn undefinedable_with_default_context[I, O](schema types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_default_context(schema, 'undefinedable', getter)
}

fn maybe_with_state_default[I, O](wrapped types.Schema[I, O], kind string, getter fn (?types.Dataset[types.Maybe[I]], types.Config) types.Maybe[I]) types.Schema[types.Maybe[I], types.Maybe[O]] {
	base := maybe_schema(wrapped, kind, []I{})
	return types.Schema[types.Maybe[I], types.Maybe[O]]{
		...base
		default_context_provider: types.DefaultContextProvider[types.Maybe[I]]{
			available: true
			get:       getter
		}
		run:                      fn [base, wrapped, kind, getter] [I, O](input types.Maybe[I], config types.Config) types.Dataset[types.Maybe[O]] {
			allowed := match kind {
				'optional' { input.state in [.missing, .undefined] }
				'exact_optional' { input.state == .missing }
				'nullable' { input.state == .null }
				'undefinedable' { input.state == .undefined }
				else { input.state != .value }
			}

			if !allowed { return types.run(base, input, config) }
			selected := getter(types.Dataset[types.Maybe[I]]{ typed: false, value: input }, config)
			value := if selected.state == .missing { types.undefined_value[I]() } else { selected }
			if value.state == .value {
				result := types.run(wrapped, value.value, config)
				return types.Dataset[types.Maybe[O]]{
					typed:     result.typed
					value:     types.some(result.value)
					issues:    result.issues
					exception: result.exception
					raw_value: result.raw_value
				}
			}
			return types.run(base, value, config)
		}
	}
}

pub fn optional_with_default_state[I, O](wrapped types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) types.Maybe[I]) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_state_default(wrapped, 'optional', getter)
}

pub fn exact_optional_with_default_state[I, O](wrapped types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) types.Maybe[I]) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_state_default(wrapped, 'exact_optional', getter)
}

pub fn nullable_with_default_state[I, O](wrapped types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) types.Maybe[I]) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_state_default(wrapped, 'nullable', getter)
}

pub fn nullish_with_default_state[I, O](wrapped types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) types.Maybe[I]) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_state_default(wrapped, 'nullish', getter)
}

pub fn undefinedable_with_default_state[I, O](wrapped types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) types.Maybe[I]) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return maybe_with_state_default(wrapped, 'undefinedable', getter)
}
