module types

pub struct Config {
pub:
	// Stop after the first issue; otherwise collect consecutive validation issues.
	abort_early bool
}
