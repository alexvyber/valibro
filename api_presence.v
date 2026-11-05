module valibro

import valibro.methods
import valibro.schemas
import valibro.types

pub fn optional[I, O](wrapped types.Schema[I, O], defaults ...I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.optional[I, O](wrapped, ...defaults)
}

pub fn exact_optional[I, O](wrapped types.Schema[I, O], defaults ...I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.exact_optional[I, O](wrapped, ...defaults)
}

pub fn nullable[I, O](wrapped types.Schema[I, O], defaults ...I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.nullable[I, O](wrapped, ...defaults)
}

pub fn nullish[I, O](wrapped types.Schema[I, O], defaults ...I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.nullish[I, O](wrapped, ...defaults)
}

pub fn non_optional[I, O](wrapped types.Schema[types.Maybe[I], types.Maybe[O]], messages ...types.ErrorMessage) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.non_optional[I, O](wrapped, ...messages)
}

pub fn non_nullable[I, O](wrapped types.Schema[types.Maybe[I], types.Maybe[O]], messages ...types.ErrorMessage) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.non_nullable[I, O](wrapped, ...messages)
}

pub fn non_nullish[I, O](wrapped types.Schema[types.Maybe[I], types.Maybe[O]], messages ...types.ErrorMessage) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.non_nullish[I, O](wrapped, ...messages)
}

pub fn fallback[I, O](schema types.Schema[I, O], value O) types.Schema[I, O] {
	return methods.fallback[I, O](schema, value)
}

pub fn fallback_fn[I, O](schema types.Schema[I, O], getter fn (I, []types.Issue) O) types.Schema[I, O] {
	return methods.fallback_fn[I, O](schema, getter)
}

pub fn get_default[I, O](schema types.Schema[I, O], configs ...types.Config) ?I {
	return methods.get_default(schema, ...configs)
}

pub fn get_fallback[I, O](schema types.Schema[I, O], configs ...types.Config) ?O {
	return methods.get_fallback(schema, ...configs)
}

pub fn get_fallback_with_context[I, O](schema types.Schema[I, O], dataset ?types.Dataset[O], configs ...types.Config) ?O {
	return methods.get_fallback_with_context(schema, dataset, ...configs)
}

pub fn fallback_with_context[I, O](schema types.Schema[I, O], getter fn (?types.Dataset[O], types.Config) O) types.Schema[I, O] {
	return methods.fallback_with_context(schema, getter)
}

pub fn unwrap[I, O](schema types.Schema[types.Maybe[I], types.Maybe[O]]) types.Schema[I, O] {
	return methods.unwrap[I, O](schema)
}

pub fn optional_with_default[I, O](schema types.Schema[I, O], getter fn (types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.optional_with_default[I, O](schema, getter)
}

pub fn exact_optional_with_default[I, O](schema types.Schema[I, O], getter fn (types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.exact_optional_with_default[I, O](schema, getter)
}

pub fn nullable_with_default[I, O](schema types.Schema[I, O], getter fn (types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.nullable_with_default[I, O](schema, getter)
}

pub fn nullish_with_default[I, O](schema types.Schema[I, O], getter fn (types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.nullish_with_default[I, O](schema, getter)
}

pub fn undefinedable_with_default[I, O](schema types.Schema[I, O], getter fn (types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.undefinedable_with_default[I, O](schema, getter)
}

pub fn get_default_with_context[I, O](schema types.Schema[I, O], dataset ?types.Dataset[I], configs ...types.Config) ?I {
	return methods.get_default_with_context(schema, dataset, ...configs)
}

pub fn optional_with_default_context[I, O](schema types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.optional_with_default_context(schema, getter)
}

pub fn exact_optional_with_default_context[I, O](schema types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.exact_optional_with_default_context(schema, getter)
}

pub fn nullable_with_default_context[I, O](schema types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.nullable_with_default_context(schema, getter)
}

pub fn nullish_with_default_context[I, O](schema types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.nullish_with_default_context(schema, getter)
}

pub fn undefinedable_with_default_context[I, O](schema types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.undefinedable_with_default_context(schema, getter)
}

pub fn unwrap_as[I, O, P, Q](schema types.Schema[I, O]) !types.Schema[P, Q] {
	return methods.unwrap_as[I, O, P, Q](schema)
}

pub fn optional_with_default_state[I, O](wrapped types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) types.Maybe[I]) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.optional_with_default_state(wrapped, getter)
}

pub fn exact_optional_with_default_state[I, O](wrapped types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) types.Maybe[I]) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.exact_optional_with_default_state(wrapped, getter)
}

pub fn nullable_with_default_state[I, O](wrapped types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) types.Maybe[I]) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.nullable_with_default_state(wrapped, getter)
}

pub fn nullish_with_default_state[I, O](wrapped types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) types.Maybe[I]) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.nullish_with_default_state(wrapped, getter)
}

pub fn undefinedable_with_default_state[I, O](wrapped types.Schema[I, O], getter fn (?types.Dataset[types.Maybe[I]], types.Config) types.Maybe[I]) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.undefinedable_with_default_state(wrapped, getter)
}

pub fn undefinedable[I, O](schema types.Schema[I, O], defaults ...I) types.Schema[types.Maybe[I], types.Maybe[O]] {
	return schemas.undefinedable[I, O](schema, ...defaults)
}
