module actions

import valibro.internal.text as textops
import valibro.types
import valibro.unicode

pub fn trim() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'trim'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: textops.trim(input, true, true)
			}
		}
	}
}

pub fn trim_start() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'trim_start'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: textops.trim(input, true, false)
			}
		}
	}
}

pub fn trim_end() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'trim_end'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: textops.trim(input, false, true)
			}
		}
	}
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

pub fn to_string() types.Action[string] {
	return types.Action[string]{
		kind:      .transformation
		type_name: 'to_string'
		run:       fn (input string) types.Dataset[string] {
			return types.Dataset[string]{
				value: input
			}
		}
	}
}
