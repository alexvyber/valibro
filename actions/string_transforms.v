module actions

import valibro.internal.text as textops
import valibro.types
import valibro.unicode

pub fn trim() types.Action[string] {
	return types.contextual_action[string]('trim', .transformation, fn (dataset types.Dataset[string], config types.Config) types.Dataset[string] {
		if !dataset.typed { return dataset }
		value := if config.javascript_text {
			textops.js_trim(dataset.value, true, true)
		} else {
			textops.trim(dataset.value, true, true)
		}
		return types.Dataset[string]{
			...dataset
			value: value
		}
	})
}

pub fn trim_start() types.Action[string] {
	return types.contextual_action[string]('trim_start', .transformation, fn (dataset types.Dataset[string], config types.Config) types.Dataset[string] {
		if !dataset.typed { return dataset }
		value := if config.javascript_text {
			textops.js_trim(dataset.value, true, false)
		} else {
			textops.trim(dataset.value, true, false)
		}
		return types.Dataset[string]{
			...dataset
			value: value
		}
	})
}

pub fn trim_end() types.Action[string] {
	return types.contextual_action[string]('trim_end', .transformation, fn (dataset types.Dataset[string], config types.Config) types.Dataset[string] {
		if !dataset.typed { return dataset }
		value := if config.javascript_text {
			textops.js_trim(dataset.value, false, true)
		} else {
			textops.trim(dataset.value, false, true)
		}
		return types.Dataset[string]{
			...dataset
			value: value
		}
	})
}

pub fn to_lower_case() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'to_lower_case'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: unicode.to_lower(input)
			}
		}
	}
}

pub fn to_upper_case() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'to_upper_case'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: unicode.to_upper(input)
			}
		}
	}
}

pub fn to_camel_case() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'to_camel_case'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: textops.format_case(input, '', false, true)
			}
		}
	}
}

pub fn to_pascal_case() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'to_pascal_case'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: textops.format_case(input, '', true, true)
			}
		}
	}
}

pub fn to_kebab_case() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'to_kebab_case'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: textops.format_case(input, '-', false, false)
			}
		}
	}
}

pub fn to_snake_case() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'to_snake_case'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: textops.format_case(input, '_', false, false)
			}
		}
	}
}

pub fn normalize(forms ...unicode.NormalizeForm) types.Action[string] {
	assert forms.len <= 1, 'normalize accepts at most one form'
	form := if forms.len == 1 { forms[0] } else { unicode.NormalizeForm.nfc }
	return types.Action[string]{
		kind:      .transformation
		type_name: 'normalize'
		run:       fn [form] (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: unicode.normalize(input, form)
			}
		}
	}
}
