module methods

import valibro.types

pub fn is_vali_error(err IError) bool {
	return err is types.ValidationError
}

pub fn schema_is_of_type[I, O](schema types.Schema[I, O], name string) bool {
	return schema.type_name == name
}

pub fn action_is_of_type[T](action types.Action[T], name string) bool {
	return action.type_name == name
}

pub fn action_is_of_kind[T](action types.Action[T], kind types.ActionKind) bool {
	return action.kind == kind
}
