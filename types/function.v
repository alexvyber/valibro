module types

pub struct Function[I, O] {
pub:
	call fn (I) O @[required]
}

pub struct FallibleFunction[I, O] {
pub:
	call fn (I) !O @[required]
}
