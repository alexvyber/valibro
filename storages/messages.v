module storages

import valibro.types

fn language(languages []string) string {
	assert languages.len <= 1, 'Expected at most one language'
	return if languages.len == 1 { languages[0] } else { '' }
}

pub fn get_global_config(context types.Context) types.Config {
	return context.config
}

pub fn set_global_config(mut context types.Context, config types.Config) {
	context.config = config
}

pub fn delete_global_config(mut context types.Context) {
	context.config = types.Config{}
}

pub fn get_global_message(context types.Context, languages ...string) ?types.ErrorMessage {
	return context.config.messages.global[language(languages)] or { return none }
}

pub fn get_schema_message(context types.Context, languages ...string) ?types.ErrorMessage {
	return context.config.messages.schema[language(languages)] or { return none }
}

pub fn get_specific_message(context types.Context, kind string, languages ...string) ?types.ErrorMessage {
	entries := (context.config.messages.specific[kind] or { return none }).clone()
	return entries[language(languages)] or { return none }
}

pub fn set_global_message(mut context types.Context, message types.ErrorMessage, languages ...string) {
	mut entries := context.config.messages.global.clone()
	entries[language(languages)] = message
	context.config = types.Config{
		...context.config
		messages: types.Messages{
			...context.config.messages
			global: entries
		}
	}
}

pub fn set_schema_message(mut context types.Context, message types.ErrorMessage, languages ...string) {
	mut entries := context.config.messages.schema.clone()
	entries[language(languages)] = message
	context.config = types.Config{
		...context.config
		messages: types.Messages{
			...context.config.messages
			schema: entries
		}
	}
}

pub fn set_specific_message(mut context types.Context, kind string, message types.ErrorMessage, languages ...string) {
	mut entries := context.config.messages.specific.clone()
	mut translations := (entries[kind] or {
		map[string]types.ErrorMessage{}
	}).clone()
	translations[language(languages)] = message
	entries[kind] = translations.clone()
	context.config = types.Config{
		...context.config
		messages: types.Messages{
			...context.config.messages
			specific: entries
		}
	}
}

pub fn delete_global_message(mut context types.Context, languages ...string) {
	mut entries := context.config.messages.global.clone()
	entries.delete(language(languages))
	context.config = types.Config{
		...context.config
		messages: types.Messages{
			...context.config.messages
			global: entries
		}
	}
}

pub fn delete_schema_message(mut context types.Context, languages ...string) {
	mut entries := context.config.messages.schema.clone()
	entries.delete(language(languages))
	context.config = types.Config{
		...context.config
		messages: types.Messages{
			...context.config.messages
			schema: entries
		}
	}
}

pub fn delete_specific_message(mut context types.Context, kind string, languages ...string) {
	mut entries := context.config.messages.specific.clone()
	mut translations := (entries[kind] or {
		map[string]types.ErrorMessage{}
	}).clone()
	translations.delete(language(languages))
	entries[kind] = translations.clone()
	context.config = types.Config{
		...context.config
		messages: types.Messages{
			...context.config.messages
			specific: entries
		}
	}
}
