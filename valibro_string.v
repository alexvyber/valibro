// String validation facade.
module valibro

import valibro.actions
import valibro.types

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
