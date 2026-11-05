module valibro

import valibro.actions
import regex.pcre
import valibro.methods
import valibro.types

pub fn min_length(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.min_length(requirement, ...messages)
}

pub fn max_length(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.max_length(requirement, ...messages)
}

pub fn starts_with(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.starts_with(requirement, ...messages)
}

pub fn ends_with(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.ends_with(requirement, ...messages)
}

pub fn check[T](predicate fn (T) bool, messages ...types.ErrorMessage) types.Action[T] {
	return actions.check[T](predicate, ...messages)
}

pub fn message[T](action types.Action[T], text types.ErrorMessage) types.Action[T] {
	return actions.message[T](action, text)
}

// message_fn adapts a callback using the public Issue alias to the shared contract.

pub fn message_fn(callback fn (Issue) string) types.ErrorMessage {
	handler := fn [callback] (issue types.Issue) string {
		return callback(Issue(issue))
	}
	return types.identified_message(types.MessageFunction(handler))
}

pub fn raw_check_with_context[T](operation fn (types.Dataset[T], types.Config) types.Dataset[T]) types.Action[T] {
	return actions.raw_check_with_context[T](operation)
}

pub fn finite(messages ...types.ErrorMessage) types.Action[f64] {
	return actions.finite(...messages)
}

pub fn integer(messages ...types.ErrorMessage) types.Action[f64] {
	return actions.integer(...messages)
}

pub fn safe_integer(messages ...types.ErrorMessage) types.Action[f64] {
	return actions.safe_integer(...messages)
}

pub fn multiple_of[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	return actions.multiple_of[T](requirement, ...messages)
}

pub fn compile_regex(pattern string, flags string) !pcre.Regex {
	return actions.compile_regex(pattern, flags)
}

pub fn regex_with_flags(pattern string, flags string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.regex_with_flags(pattern, flags, ...messages)
}

pub fn regex_object(regexp pcre.Regex, messages ...types.ErrorMessage) types.Action[string] {
	return actions.regex_object(regexp, ...messages)
}

pub fn base64(messages ...types.ErrorMessage) types.Action[string] {
	return actions.base64(...messages)
}

pub fn bic(messages ...types.ErrorMessage) types.Action[string] {
	return actions.bic(...messages)
}

pub fn cuid2(messages ...types.ErrorMessage) types.Action[string] {
	return actions.cuid2(...messages)
}

pub fn decimal(messages ...types.ErrorMessage) types.Action[string] {
	return actions.decimal(...messages)
}

pub fn digits(messages ...types.ErrorMessage) types.Action[string] {
	return actions.digits(...messages)
}

pub fn domain(messages ...types.ErrorMessage) types.Action[string] {
	return actions.domain(...messages)
}

pub fn email(messages ...types.ErrorMessage) types.Action[string] {
	return actions.email(...messages)
}

pub fn hexadecimal(messages ...types.ErrorMessage) types.Action[string] {
	return actions.hexadecimal(...messages)
}

pub fn hex_color(messages ...types.ErrorMessage) types.Action[string] {
	return actions.hex_color(...messages)
}

pub fn ipv4(messages ...types.ErrorMessage) types.Action[string] {
	return actions.ipv4(...messages)
}

pub fn ipv6(messages ...types.ErrorMessage) types.Action[string] {
	return actions.ipv6(...messages)
}

pub fn ip(messages ...types.ErrorMessage) types.Action[string] {
	return actions.ip(...messages)
}

pub fn iso_date(messages ...types.ErrorMessage) types.Action[string] {
	return actions.iso_date(...messages)
}

pub fn iso_date_time(messages ...types.ErrorMessage) types.Action[string] {
	return actions.iso_date_time(...messages)
}

pub fn iso_date_time_second(messages ...types.ErrorMessage) types.Action[string] {
	return actions.iso_date_time_second(...messages)
}

pub fn iso_time(messages ...types.ErrorMessage) types.Action[string] {
	return actions.iso_time(...messages)
}

pub fn iso_time_second(messages ...types.ErrorMessage) types.Action[string] {
	return actions.iso_time_second(...messages)
}

pub fn iso_timestamp(messages ...types.ErrorMessage) types.Action[string] {
	return actions.iso_timestamp(...messages)
}

pub fn iso_week(messages ...types.ErrorMessage) types.Action[string] {
	return actions.iso_week(...messages)
}

pub fn jws_compact(messages ...types.ErrorMessage) types.Action[string] {
	return actions.jws_compact(...messages)
}

pub fn isrc(messages ...types.ErrorMessage) types.Action[string] {
	return actions.isrc(...messages)
}

pub fn ksuid(messages ...types.ErrorMessage) types.Action[string] {
	return actions.ksuid(...messages)
}

pub fn mac(messages ...types.ErrorMessage) types.Action[string] {
	return actions.mac(...messages)
}

pub fn mac48(messages ...types.ErrorMessage) types.Action[string] {
	return actions.mac48(...messages)
}

pub fn mac64(messages ...types.ErrorMessage) types.Action[string] {
	return actions.mac64(...messages)
}

pub fn nanoid(messages ...types.ErrorMessage) types.Action[string] {
	return actions.nanoid(...messages)
}

pub fn octal(messages ...types.ErrorMessage) types.Action[string] {
	return actions.octal(...messages)
}

pub fn rfc_email(messages ...types.ErrorMessage) types.Action[string] {
	return actions.rfc_email(...messages)
}

pub fn slug(messages ...types.ErrorMessage) types.Action[string] {
	return actions.slug(...messages)
}

pub fn ulid(messages ...types.ErrorMessage) types.Action[string] {
	return actions.ulid(...messages)
}

pub fn uuid(messages ...types.ErrorMessage) types.Action[string] {
	return actions.uuid(...messages)
}

pub fn length(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.length(requirement, ...messages)
}

pub fn not_length(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.not_length(requirement, ...messages)
}

pub fn bytes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.bytes(requirement, ...messages)
}

pub fn min_bytes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.min_bytes(requirement, ...messages)
}

pub fn max_bytes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.max_bytes(requirement, ...messages)
}

pub fn not_bytes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.not_bytes(requirement, ...messages)
}

pub fn code_points(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.code_points(requirement, ...messages)
}

pub fn min_code_points(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.min_code_points(requirement, ...messages)
}

pub fn max_code_points(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.max_code_points(requirement, ...messages)
}

pub fn not_code_points(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.not_code_points(requirement, ...messages)
}

pub fn empty(messages ...types.ErrorMessage) types.Action[string] {
	return actions.empty(...messages)
}

pub fn non_empty(messages ...types.ErrorMessage) types.Action[string] {
	return actions.non_empty(...messages)
}

pub fn credit_card(messages ...types.ErrorMessage) types.Action[string] {
	return actions.credit_card(...messages)
}

pub fn imei(messages ...types.ErrorMessage) types.Action[string] {
	return actions.imei(...messages)
}

pub fn isbn(messages ...types.ErrorMessage) types.Action[string] {
	return actions.isbn(...messages)
}

pub fn includes(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.includes(requirement, ...messages)
}

pub fn excludes(requirement string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.excludes(requirement, ...messages)
}

pub fn value[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	return actions.value[T](requirement, ...messages)
}

pub fn not_value[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	return actions.not_value[T](requirement, ...messages)
}

pub fn values[T](requirements []T, messages ...types.ErrorMessage) types.Action[T] {
	return actions.values[T](requirements, ...messages)
}

pub fn not_values[T](requirements []T, messages ...types.ErrorMessage) types.Action[T] {
	return actions.not_values[T](requirements, ...messages)
}

pub fn min_value[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	return actions.min_value[T](requirement, ...messages)
}

pub fn max_value[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	return actions.max_value[T](requirement, ...messages)
}

pub fn gt_value[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	return actions.gt_value[T](requirement, ...messages)
}

pub fn lt_value[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	return actions.lt_value[T](requirement, ...messages)
}

pub fn hash(algorithms []types.HashType, messages ...types.ErrorMessage) types.Action[string] {
	return actions.hash(algorithms, ...messages)
}

pub fn regex(pattern string, messages ...types.ErrorMessage) types.Action[string] {
	return actions.regex(pattern, ...messages)
}

pub fn url(messages ...types.ErrorMessage) types.Action[string] {
	return actions.url(...messages)
}

pub fn partial_check[I, O](schema types.Schema[I, O], paths [][]types.PathSegment, predicate fn (O) bool, messages ...types.ErrorMessage) types.Schema[I, O] {
	return methods.partial_check[I, O](schema, paths, predicate, ...messages)
}

pub fn raw_check[T](operation fn (T) []types.Issue) types.Action[T] {
	return actions.raw_check[T](operation)
}

pub fn graphemes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.graphemes(requirement, ...messages)
}

pub fn min_graphemes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.min_graphemes(requirement, ...messages)
}

pub fn max_graphemes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.max_graphemes(requirement, ...messages)
}

pub fn not_graphemes(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.not_graphemes(requirement, ...messages)
}

pub fn words(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.words(requirement, ...messages)
}

pub fn min_words(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.min_words(requirement, ...messages)
}

pub fn max_words(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.max_words(requirement, ...messages)
}

pub fn not_words(requirement int, messages ...types.ErrorMessage) types.Action[string] {
	return actions.not_words(requirement, ...messages)
}

pub fn emoji(messages ...types.ErrorMessage) types.Action[string] {
	return actions.emoji(...messages)
}

pub fn finite_of[T](messages ...types.ErrorMessage) types.Action[T] {
	return actions.finite_of[T](...messages)
}

pub fn integer_of[T](messages ...types.ErrorMessage) types.Action[T] {
	return actions.integer_of[T](...messages)
}

pub fn safe_integer_of[T](messages ...types.ErrorMessage) types.Action[T] {
	return actions.safe_integer_of[T](...messages)
}
