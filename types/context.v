module types

pub fn (context Context) message(lang string) ?ErrorMessage {
	return context.config.messages.defaults[lang] or { return none }
}

pub fn (context Context) schema_message(lang string) ?ErrorMessage {
	return context.config.messages.schema[lang] or { return none }
}

pub fn (context Context) specific_message(kind string, lang string) ?ErrorMessage {
	entries := (context.config.messages.specific[kind] or { return none }).clone()
	return entries[lang] or { return none }
}

pub fn (mut context Context) set_message(message ErrorMessage, lang string) {
	mut entries := context.config.messages.defaults.clone()
	entries[lang] = message
	context.config = Config{
		...context.config
		messages: Messages{
			...context.config.messages
			defaults: entries
		}
	}
}

pub fn (mut context Context) set_schema_message(message ErrorMessage, lang string) {
	mut entries := context.config.messages.schema.clone()
	entries[lang] = message
	context.config = Config{
		...context.config
		messages: Messages{
			...context.config.messages
			schema: entries
		}
	}
}

pub fn (mut context Context) set_specific_message(kind string, message ErrorMessage, lang string) {
	mut entries := context.config.messages.specific.clone()
	mut translations := (entries[kind] or {
		map[string]ErrorMessage{}
	}).clone()
	translations[lang] = message
	entries[kind] = translations.clone()
	context.config = Config{
		...context.config
		messages: Messages{
			...context.config.messages
			specific: entries
		}
	}
}

pub fn (mut context Context) delete_message(lang string) {
	mut entries := context.config.messages.defaults.clone()
	entries.delete(lang)
	context.config = Config{
		...context.config
		messages: Messages{
			...context.config.messages
			defaults: entries
		}
	}
}

pub fn (mut context Context) delete_schema_message(lang string) {
	mut entries := context.config.messages.schema.clone()
	entries.delete(lang)
	context.config = Config{
		...context.config
		messages: Messages{
			...context.config.messages
			schema: entries
		}
	}
}

pub fn (mut context Context) delete_specific_message(kind string, lang string) {
	mut entries := context.config.messages.specific.clone()
	mut translations := (entries[kind] or {
		map[string]ErrorMessage{}
	}).clone()
	translations.delete(lang)
	entries[kind] = translations.clone()
	context.config = Config{
		...context.config
		messages: Messages{
			...context.config.messages
			specific: entries
		}
	}
}
