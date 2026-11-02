module valibro_test

import valibro as v
import valibro.actions
import valibro.methods
import valibro.schemas
import valibro.types

fn test_username_pipeline() {
	schema := v.pipe(v.string(), v.trim(), v.to_lower_case(), v.min_length(3), v.max_length(32))
	result := v.safe_parse(schema, '  Alex  ')
	assert result.success
	assert result.output or { panic('Missing output') } == 'alex'
	assert result.issues.len == 0
	assert v.parse(schema, '  Alex  ') or { panic(err) } == 'alex'
}

fn test_failure_has_no_output_and_structured_issues() {
	result := v.safe_parse(v.pipe(v.string(), v.min_length(3)), 'a')
	assert !result.success
	assert result.output == none
	assert result.issues.len == 1
	issue := result.issues[0]
	assert issue.code == 'min_length'
	assert issue.expected == '>=3'
	assert issue.received == '1'
	assert issue.path.len == 0
}

fn test_collects_issues_in_order_and_can_abort_early() {
	schema := v.pipe(v.string(), v.min_length(5), v.starts_with('x'), v.ends_with('z'))
	result := v.safe_parse(schema, 'a')
	assert result.issues.map(it.code) == ['min_length', 'starts_with', 'ends_with']
	first := v.safe_parse_with_config(schema, 'a', v.Config{ abort_early: true })
	assert first.issues.len == 1
	assert first.issues[0].code == 'min_length'
}

fn test_transformations_stop_after_failure() {
	// The transform would panic if called. No later validation may run either.
	transform := types.Action[string]{
		kind:      .transformation
		type_name: 'must_not_run'
		run:       fn (input string) types.Dataset[string] {
			panic('Transformation ran after validation failed')
		}
	}
	schema := v.pipe(v.string(), v.min_length(3), transform, v.ends_with('z'))
	result := v.safe_parse(schema, 'a')
	assert result.issues.len == 1
}

fn test_code_point_lengths_and_boundaries() {
	schema := v.pipe(v.string(), v.min_code_points(2), v.max_code_points(2))
	assert v.safe_parse(schema, 'ёж').success
	assert v.safe_parse(schema, '🙂🙂').success
	assert !v.safe_parse(schema, '🙂').success
	assert !v.safe_parse(schema, '🙂🙂🙂').success
	assert v.safe_parse(v.pipe(v.string(), v.min_code_points(0), v.max_code_points(0)), '').success
	// A combining accent is a separate code point.
	assert v.safe_parse(schema, 'e\u0301').success
}

fn test_custom_check_and_message() {
	rule := v.check(fn (value string) bool {
		return value != 'admin'
	}, 'Reserved username')
	schema := v.pipe(v.string(), rule)
	assert v.safe_parse(schema, 'alex').success
	assert v.safe_parse(schema, 'admin').issues[0].message == 'Reserved username'
	original := v.min_length(3)
	custom := v.message(original, 'Too short')
	assert v.safe_parse(v.pipe(v.string(), custom), 'x').issues[0].message == 'Too short'
	assert v.safe_parse(v.pipe(v.string(), original), 'x').issues[0].message != 'Too short'
	assert v.safe_parse(v.pipe(v.string(), custom), 'alex').success
}

fn test_parse_returns_inspectable_validation_error() {
	schema := v.pipe(v.string(), v.min_length(3), v.starts_with('x'))
	v.parse(schema, 'a') or {
		assert err is types.ValidationError
		if err is types.ValidationError {
			assert err.issues.len == 2
			assert err.code() == 1
			assert err.msg().contains('Invalid length')
		}
		return
	}
	assert false, 'Expected parse to fail'
}

fn test_parse_with_config() {
	v.parse_with_config(v.pipe(v.string(), v.min_length(3), v.ends_with('z')), 'a', v.Config{
		abort_early: true
	}) or {
		if err is types.ValidationError {
			assert err.issues.len == 1
			return
		}
		panic('Unexpected error type')
	}
	assert false, 'Expected parse to fail'
}

fn test_pipeline_reuse_and_nested_composition() {
	base := v.string()
	short := v.pipe(base, v.max_length(2))
	long := v.pipe(base, v.min_length(3))
	assert v.safe_parse(base, 'abc').success
	assert !v.safe_parse(short, 'abc').success
	assert v.safe_parse(long, 'abc').success
	assert v.safe_parse(short, 'ab').success
	assert !v.safe_parse(long, 'ab').success
	composed := v.pipe(v.pipe(base, v.trim()), v.to_lower_case(), v.starts_with('a'),
		v.ends_with('x'))
	assert v.parse(composed, '  ALEX  ') or { panic(err) } == 'alex'
	assert v.parse(v.pipe(base), 'unchanged') or { panic(err) } == 'unchanged'
}

fn test_direct_submodule_imports() {
	schema := methods.pipe(schemas.string(), actions.trim(), actions.min_length(2))
	assert methods.parse(schema, ' ok ') or { panic(err) } == 'ok'
}

fn test_generic_extension_and_structured_paths() {
	schema := types.Schema[int, int]{
		type_name: 'int'
		run:       fn (input int, config types.Config) types.Dataset[int] {
			return types.Dataset[int]{
				value: input
			}
		}
	}
	positive := v.pipe(schema, v.check(fn (value int) bool {
		return value > 0
	}, 'Must be positive'))
	assert v.parse(positive, 42) or { panic(err) } == 42
	assert !v.safe_parse(positive, -1).success
	custom := v.message(v.check(fn (value int) bool {
		return value > 0
	}, 'Positive'), 'Custom integer issue')
	assert v.safe_parse(v.pipe(schema, custom), -1).issues[0].message == 'Custom integer issue'
	issue := v.Issue{
		code:    'custom'
		message: 'Invalid'
		path:    [types.PathSegment('users'), types.PathSegment(0)]
	}
	assert issue.path.len == 2
}
