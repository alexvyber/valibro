module jsoncodec

pub type Indent = int | string

@[params]
pub struct ParseConfig {
pub:
	binary64_numbers bool
}

@[params]
pub struct StringifyConfig {
pub:
	binary64_numbers bool
	space            Indent
	max_depth        int
}
