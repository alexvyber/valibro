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

pub struct Examples[T] {
pub:
	present bool
	values  []T
}

pub struct DefaultProvider[T] {
pub:
	available bool
	get       fn (Config) T @[required]
}

// A computed default can inspect an optional input dataset and configuration.
pub struct DefaultContextProvider[T] {
pub:
	available bool
	get       fn (?Dataset[T], Config) T @[required]
}
