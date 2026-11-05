module valibro_test

import valibro as v
import valibro.types

fn test_localization_precedence_and_context_isolation() {
	mut context := v.Context{}
	assert v.get_global_message(context) == none
	v.set_global_message(mut context, 'Global')
	v.set_schema_message(mut context, 'Schema')
	v.set_specific_message(mut context, 'min_length', 'Short')
	assert v.get_global_message(context) or { panic('message') } == types.ErrorMessage('Global')
	invalid := v.pipe(v.string(), v.min_length(3))
	assert v.safe_parse_with_config(invalid, 'x', context.config).issues[0].message == 'Short'
	assert v.safe_parse_with_config(v.literal('a'), 'b', context.config).issues[0].message == 'Schema'
	assert v.safe_parse_with_config(v.pipe(v.string(), v.ends_with('z')), 'a', context.config).issues[0].message == 'Global'
	assert v.safe_parse_with_config(v.pipe(v.string(), v.min_length(3, 'Custom')), 'a',
		context.config).issues[0].message == 'Custom'
	v.set_specific_message(mut context, 'min_length', 'Коротко', 'ru')
	translated := v.Config{
		...context.config
		lang: 'ru'
	}
	assert v.safe_parse_with_config(invalid, 'x', translated).issues[0].message == 'Коротко'
	v.delete_specific_message(mut context, 'min_length')
	assert v.safe_parse_with_config(invalid, 'x', context.config).issues[0].message == 'Global'
	configured := v.config(invalid, v.Config{ message: types.ErrorMessage('Configured') })
	assert v.safe_parse(configured, 'x').issues[0].message == 'Configured'
	assert v.safe_parse_with_config(configured, 'x', context.config).issues[0].message == 'Configured'
	fresh := v.Context{}
	assert v.get_global_message(fresh) == none
	v.delete_global_message(mut context)
	v.delete_schema_message(mut context)
	assert v.get_global_message(context) == none
	v.delete_global_config(mut context)
	assert context.config.lang == ''
}

fn test_presence_and_recovery_callbacks_use_context_messages() {
	mut context := v.Context{}
	v.set_schema_message(mut context, 'Schema context')
	absent := v.safe_parse_with_config(v.nullable(v.string()), types.missing[string](),
		context.config)
	assert absent.issues[0].message == 'Schema context'
	recovery := v.fallback_fn(v.literal('a'), fn (input string, issues []types.Issue) string {
		return issues[0].message
	})
	assert v.parse_with_config(recovery, 'b', context.config) or { panic(err) } == 'Schema context'
}
