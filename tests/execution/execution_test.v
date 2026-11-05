module valibro_test

import valibro as v
import valibro.types

struct Account {
	name     string
	password string
	confirm  string
	age      f64
}

fn account_schema() types.Schema[Account, Account] {
	return v.object[Account](v.field('name', fn (a Account) string {
		return a.name
	}, fn (a Account, x string) Account {
		return Account{
			...a
			name: x
		}
	}, v.pipe(v.string(), v.trim(), v.min_length(2))), v.field('age', fn (a Account) f64 {
		return a.age
	}, fn (a Account, x f64) Account {
		return Account{
			...a
			age: x
		}
	}, v.pipe(v.number(), v.integer(), v.min_value(0.0))))
}

fn test_struct_fields_and_partial_cross_field_validation() {
	schema := account_schema()
	output := v.parse(schema, Account{ name: ' hi ', age: 42 }) or { panic(err) }
	assert output.name == 'hi'
	bad := v.safe_parse(schema, Account{ name: 'a', age: -1 })
	assert bad.issues.len == 2
	assert v.get_dot_path(bad.issues[0]) == 'name'
	cross := v.partial_check(schema, [[types.PathSegment('password')],
		[types.PathSegment('confirm')]], fn (a Account) bool {
		return a.password == a.confirm
	}, 'Passwords differ')
	result := v.safe_parse(cross, Account{ name: 'a', age: 1, password: 'a', confirm: 'b' })
	assert result.issues.map(it.code) == ['min_length', 'partial_check']
}

fn test_function_argument_and_return_contracts() {
	schema := v.function_schema[string, string]()
	validated := v.pipe_to(schema, v.args[string, string, string](v.pipe(v.string(), v.trim(),
		v.min_length(2))))
	raw := fn (s string) string {
		return s + '!'
	}
	function := v.parse(validated, types.Function[string, string]{ call: raw }) or { panic(err) }
	assert function.call(' hi ') or { panic(err) } == 'hi!'
	function.call('a') or {
		assert err is types.ValidationError
		return
	}
	assert false, 'Expected argument validation failure'
}

fn test_function_return_contract() {
	schema := v.function_schema[string, f64]()
	validated := v.pipe_to(schema, v.returns[string, f64, f64](v.pipe(v.number(), v.integer())))
	raw := fn (s string) f64 {
		return s.f64()
	}
	function := v.parse(validated, types.Function[string, f64]{ call: raw }) or { panic(err) }
	assert function.call('42') or { panic(err) } == 42.0
	function.call('1.5') or {
		assert err is types.ValidationError
		return
	}
	assert false, 'Expected return validation failure'
}

fn test_async_and_abort_pipe_config() {
	schema := v.pipe(v.string(), v.min_length(3), v.starts_with('x'))
	pending := v.safe_parse_async(schema, 'abc')
	result := <-pending
	assert !result.success
	assert result.issues.map(it.code) == ['starts_with']
	configured := v.array(schema)
	outcome := v.safe_parse_with_config(configured, ['a', 'b'], v.Config{ abort_pipe_early: true })
	assert outcome.issues.map(it.code) == ['min_length', 'min_length']
}

fn test_cache_capacity_and_configuration_are_part_of_key() {
	schema := v.cache(v.pipe(v.string(), v.min_length(3), v.starts_with('x')), fn (s string) string {
		return s
	}, 2)
	for value in ['abc', 'x', 'xyz', 'abc', 'x', 'xyz'] {
		output := v.safe_parse(schema, value)
		assert output.success == (value == 'xyz')
	}
	assert v.safe_parse_with_config(schema, 'a', v.Config{ abort_early: true }).issues.len == 1
	assert v.safe_parse(schema, 'a').issues.len == 2
}

fn test_futures_symbols_defaults_and_unwrap() {
	future := v.parse_async(v.pipe(v.string(), v.trim()), ' hi ')
	assert future.await() or { panic(err) } == 'hi'
	assert future.await() or { panic(err) } == 'hi'
	awaited := v.pipe_to(v.promise[string](), v.await_future[string]())
	assert v.parse(awaited, future) or { panic(err) } == 'hi'
	assert v.is_valid(v.symbol(), types.symbol('name'))
	assert types.symbol('name') != types.symbol('name')
	assert v.is_valid(v.null_schema(), types.Null{})
	assert v.is_valid(v.undefined_schema(), types.Undefined{})
	assert v.is_valid(v.void_schema(), types.Undefined{})
	optional := v.optional(v.pipe(v.string(), v.trim()), ' default ')
	assert v.get_default(optional) or { panic('default') } == types.some(' default ')
	assert v.parse(v.unwrap(optional), ' hi ') or { panic(err) } == 'hi'
	assert v.get_fallback(v.fallback(v.string(), 'fallback')) or { panic('fallback') } == 'fallback'
	assert v.is_valid(v.undefinedable(v.string()), types.undefined_value[string]())
	assert !v.is_valid(v.undefinedable(v.string()), types.missing[string]())
}

fn test_default_providers_and_combined_function_contracts() {
	schema := v.optional_with_default(v.pipe(v.string(), v.trim()), fn (config v.Config) string {
		return ' ' + config.lang + ' '
	})
	result := v.safe_parse_with_config(schema, types.missing[string](), v.Config{ lang: 'ru' })
	assert result.output or { panic('output') } == types.some('ru')
	assert v.get_default(schema, v.Config{ lang: 'en' }) or { panic('default') } == types.some(' en ')
	callable := v.function_schema[string, f64]()
	arguments := v.pipe_to(callable, v.args[string, string, f64](v.pipe(v.string(), v.trim(),
		v.min_length(1))))
	checked := v.pipe_to(arguments, v.returns_checked[string, f64, f64](v.pipe(v.number(),
		v.integer())))
	raw := types.Function[string, f64]{
		call: fn (s string) f64 {
			return s.f64()
		}
	}
	function := v.parse(checked, raw) or { panic(err) }
	assert function.call(' 42 ') or { panic(err) } == 42.0
	function.call('1.5') or {
		assert v.is_vali_error(err)
		return
	}
	assert false, 'Expected return validation failure'
}

struct Calls {
mut:
	value int
}

fn test_cache_actually_reuses_results_and_evicts_least_recently_used() {
	mut calls := &Calls{}
	counted := v.pipe(v.string(), v.transform(fn [mut calls] (input string) string {
		calls.value++
		return input
	}))
	cached := v.cache(counted, fn (s string) string {
		return s
	}, 2)
	for input in ['a', 'a', 'b', 'a', 'c', 'b'] {
		v.parse(cached, input) or { panic(err) }
	}
	assert calls.value == 4
	assert v.is_of_kind(v.string(), 'schema')
	assert v.is_of_kind(v.trim(), 'transformation')
	assert v.is_of_type(v.string(), 'string')
	asynchronous := v.parser_async(v.pipe(v.string(), v.trim()))
	future := asynchronous(' hi ')
	assert future.await() or { panic(err) } == 'hi'
}

fn test_cache_does_not_mix_defaults_from_different_message_configs() {
	native := v.optional_with_default(v.string(), fn (config v.Config) string {
		if message := config.message { return types.resolve_message(message, types.Issue{}) }
		return 'unset'
	})
	cached := v.cache(native, fn (input types.Maybe[string]) string {
		return input.state.str()
	}, 2)
	for message in ['one', 'two'] {
		result := v.parse_with_config(cached, types.missing[string](), v.Config{
			message: types.ErrorMessage(message)
		}) or { panic(err) }
		assert result == types.some(message)
	}
	first := v.message_fn(fn (issue v.Issue) string {
		return 'first'
	})
	second := v.message_fn(fn (issue v.Issue) string {
		return 'second'
	})
	assert v.parse_with_config(cached, types.missing[string](), v.Config{
		message: first
	}) or { panic(err) } == types.some('first')
	assert v.parse_with_config(cached, types.missing[string](), v.Config{
		message: second
	}) or { panic(err) } == types.some('second')
}

struct CacheClock {
mut:
	now   i64
	calls int
}

fn test_cache_expiration_refresh_controls_and_zero_capacity() {
	mut clock := &CacheClock{}
	schema := v.pipe(v.string(), v.transform(fn [mut clock] (input string) string {
		clock.calls++
		return input
	}))
	cached := v.cached(schema, fn (input string) string {
		return input
	}, v.CacheConfig{
		max_size:   2
		max_age_ms: i64(100)
		now:        fn [clock] () i64 {
			return clock.now
		}
	})
	assert v.parse(cached.schema, 'a') or { panic(err) } == 'a'
	clock.now = 100
	assert v.parse(cached.schema, 'a') or { panic(err) } == 'a'
	assert clock.calls == 1
	clock.now = 101
	assert v.parse(cached.schema, 'a') or { panic(err) } == 'a'
	assert clock.calls == 2
	key := cached.key('a', v.Config{})
	cached.set(key, types.Dataset[string]{ value: 'manual' })
	assert v.parse(cached.schema, 'a') or { panic(err) } == 'manual'
	assert (cached.get(key) or { panic('cache miss') }).value == 'manual'
	cached.clear()
	assert cached.get(key) == none
	assert v.parse(cached.schema, 'a') or { panic(err) } == 'a'
	assert clock.calls == 3
	uncached := v.cache_with_config(schema, fn (input string) string {
		return input
	}, v.CacheConfig{ max_size: 0 })
	for _ in 0 .. 2 {
		v.parse(uncached, 'x') or { panic(err) }
	}
	assert clock.calls == 5
}

fn test_function_contracts_capture_parse_configuration() {
	checks := v.pipe(v.string(), v.min_length(3), v.ends_with('z'))
	schema := v.pipe_to(v.function_schema[string, string](), v.args[string, string, string](checks))
	input := types.Function[string, string]{
		call: fn (value string) string {
			return value
		}
	}
	function := v.parse_with_config(schema, input, v.Config{
		abort_early: true
		message:     types.ErrorMessage('Argument config')
	}) or { panic(err) }
	function.call('a') or {
		assert err is types.ValidationError
		if err is types.ValidationError {
			assert err.issues.len == 1
			assert err.issues[0].message == 'Argument config'
		}
		return
	}
	assert false, 'Expected argument contract failure'
}

fn test_return_contracts_capture_parse_configuration() {
	checks := v.pipe(v.number(), v.integer(), v.min_value(10.0))
	schema := v.pipe_to(v.function_schema[string, f64](), v.returns[string, f64, f64](checks))
	input := types.Function[string, f64]{
		call: fn (value string) f64 {
			return 1.5
		}
	}
	function := v.parse_with_config(schema, input, v.Config{
		abort_early: true
		message:     types.ErrorMessage('Return config')
	}) or { panic(err) }
	function.call('a') or {
		assert err is types.ValidationError
		if err is types.ValidationError {
			assert err.issues.len == 1
			assert err.issues[0].message == 'Return config'
		}
		return
	}
	assert false, 'Expected return contract failure'
}
