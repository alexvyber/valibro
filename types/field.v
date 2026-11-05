module types

pub struct Field[I, O] {
pub:
	name string
	run  fn (I, O, Config) Dataset[O] @[required]
}
