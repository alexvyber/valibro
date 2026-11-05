module types

import x.json2

pub struct Annotations {
pub:
	title       ?string
	description ?string
	metadata    map[string]json2.Any
}

pub struct Examples[T] {
pub:
	present bool
	values  []T
}
