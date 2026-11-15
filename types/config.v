module types

@[params]
pub struct Config {
pub:
	// Stop after the first issue; otherwise collect consecutive validation issues.
	javascript_text  bool
	abort_early      bool
	abort_pipe_early bool
	lang             string
	message          ?ErrorMessage
	messages         Messages
}
