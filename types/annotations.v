module types

import x.json2

pub struct Annotations {
pub:
	title       ?string
	description ?string
	examples    ?[]string
	metadata    map[string]json2.Any
}

// Marker types make brands/flavors distinct at compile time in V.
pub struct Branded[T, B] {
pub:
	value T
	tag   ?B
}

pub struct Flavored[T, B] {
pub:
	value T
	tag   ?B
}
