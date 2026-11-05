module actions

import valibro.internal.diagnostics
import valibro.types

fn collection_count[T](input T) int {
	$if T is string {
		return input.runes().len
	} $else $if T is $array || T is $map {
		return input.len
	} $else $if T is types.Countable {
		return input.count()
	} $else {
		$compile_error('Measurement requires a string, array, or map')
	}
}

fn measure[T](kind string, requirement int, relation string, messages []types.ErrorMessage) types.Action[T] {
	return count_check[T](kind, requirement, relation, fn [T](input T) int {
		return collection_count[T](input)
	}, messages)
}

pub fn empty_of[T](messages ...types.ErrorMessage) types.Action[T] {
	return measure[T]('empty', 0, '=', messages)
}

pub fn non_empty_of[T](messages ...types.ErrorMessage) types.Action[T] {
	return measure[T]('non_empty', 0, '!=', messages)
}

fn measure_entries[T](kind string, requirement int, relation string, messages []types.ErrorMessage) types.Action[T] {
	return count_check[T](kind, requirement, relation, fn [T](input T) int {
		$if T is $struct {
			mut count := 0
			$for field in T.fields {
				_ = field.name
				count++
			}
			return count
		} $else {
			return collection_count[T](input)
		}
	}, messages)
}

pub fn length_of[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return measure[T]('length', requirement, '=', messages)
}

pub fn min_length_of[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return measure[T]('min_length', requirement, '>=', messages)
}

pub fn max_length_of[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return measure[T]('max_length', requirement, '<=', messages)
}

pub fn not_length_of[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return measure[T]('not_length', requirement, '!=', messages)
}

pub fn entries[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return measure_entries[T]('entries', requirement, '=', messages)
}

pub fn min_entries[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return measure_entries[T]('min_entries', requirement, '>=', messages)
}

pub fn max_entries[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return measure_entries[T]('max_entries', requirement, '<=', messages)
}

pub fn not_entries[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return measure_entries[T]('not_entries', requirement, '!=', messages)
}

pub fn size[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return measure[T]('size', requirement, '=', messages)
}

pub fn min_size[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return measure[T]('min_size', requirement, '>=', messages)
}

pub fn max_size[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return measure[T]('max_size', requirement, '<=', messages)
}

pub fn not_size[T](requirement int, messages ...types.ErrorMessage) types.Action[T] {
	return measure[T]('not_size', requirement, '!=', messages)
}

pub fn mime_type[T](requirements []string, messages ...types.ErrorMessage) types.Action[T] {
	$if T is types.Blob || T is types.File {
	} $else {
		$compile_error('mime_type requires a Blob or File')
	}
	items := requirements.clone()
	expected := diagnostics.joined_values[string](items)
	text := custom_message(messages, '')
	return types.Action[T]{
		kind:      .validation
		type_name: 'mime_type'
		run:       fn [items, expected, text] [T](input T) types.Dataset[T] {
			if input.mime_type in items { return types.Dataset[T]{
					value: input
				} }
			return validation_failure[T](input, 'mime_type', 'MIME type', expected, '"' +
				input.mime_type + '"', text)
		}
	}
}
