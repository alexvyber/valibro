module valibro_test

import os
import rand

fn test_primitive_type_errors_and_invalid_factory_arguments() {
	root := @VMODROOT
	work := os.join_path(os.temp_dir(), 'valibro-primitives-${rand.ulid()}')
	os.mkdir_all(work) or { panic(err) }
	defer { os.rmdir_all(work) or {} }
	compiler := os.quoted_path(@VEXE)
	imports := os.quoted_path('${root}/..|@vlib|@vmodules')
	source := os.join_path(work, 'main.v')
	// Unsupported schema/action types and mismatched pipeline types fail at compile time.
	cases := [
		'v.number_of[string]()',
		'v.multiple_of(true)',
		'v.min_value(true)',
		"v.safe_parse(v.number(), '42')",
		'v.pipe(v.number(), v.min_value(1))',
	]
	expected := ['number_of requires', 'multiple_of requires', 'Value ordering requires', 'string',
		'Action[int]']
	for i, expression in cases {
		os.write_file(source, 'module main\nimport valibro as v\nfn main() { ${expression} }\n') or {
			panic(err)
		}
		checked := os.execute('${compiler} -path ${imports} -check ${os.quoted_path(source)}')
		assert checked.exit_code != 0, expression
		assert checked.output.contains(expected[i]), '${expression}: ${checked.output}'
	}
	fixture := os.join_path(root, 'tests', 'fixtures', 'primitives/contracts',
		'invalid_factories.vv')
	os.cp(fixture, source) or { panic(err) }
	executable := os.join_path(work, 'invalid_factories')
	built :=
		os.execute('${compiler} -path ${imports} -o ${os.quoted_path(executable)} ${os.quoted_path(source)}')
	assert built.exit_code == 0, built.output
	for name in ['number_messages', 'boolean_messages', 'bigint_messages', 'date_messages',
		'action_messages'] {
		result := os.execute('${os.quoted_path(executable)} ${name}')
		assert result.exit_code != 0, name
		assert result.output.contains('at most one'), result.output
	}
}
