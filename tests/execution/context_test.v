module valibro_test

import valibro.tests.support
import valibro as v
import valibro.types

fn test_localization_precedence_and_context_isolation() {
	mut context := v.Context{}
	assert context.message('') == none
	context.set_message('Global', '')
	context.set_schema_message('Schema', '')
	context.set_specific_message('min_length', 'Short', '')
	assert context.message('') or { panic('message') } == types.ErrorMessage('Global')
	invalid := v.pipe(v.string(), v.min_length(3))
	assert support.observe(invalid, 'x', context.config).issues[0].message == 'Short'
	assert support.observe(v.literal('a'), 'b', context.config).issues[0].message == 'Schema'
	assert support.observe(v.pipe(v.string(), v.ends_with('z')), 'a', context.config).issues[0].message == 'Global'
	assert support.observe(v.pipe(v.string(), v.min_length(3, 'Custom')), 'a', context.config).issues[0].message == 'Custom'
	context.set_specific_message('min_length', 'Коротко', 'ru')
	translated := v.Config{
		...context.config
		lang: 'ru'
	}
	assert support.observe(invalid, 'x', translated).issues[0].message == 'Коротко'
	context.delete_specific_message('min_length', '')
	assert support.observe(invalid, 'x', context.config).issues[0].message == 'Global'
	configured := v.config(invalid, v.Config{ message: types.ErrorMessage('Configured') })
	assert support.observe(configured, 'x').issues[0].message == 'Configured'
	assert support.observe(configured, 'x', context.config).issues[0].message == 'Configured'
	fresh := v.Context{}
	assert fresh.message('') == none
	context.delete_message('')
	context.delete_schema_message('')
	assert context.message('') == none
	context.config = v.Config{}
	assert context.config.lang == ''
}
