module valibro_test

import valibro.tests.support
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
	bad := support.observe(schema, Account{ name: 'a', age: -1 })
	assert bad.issues.len == 2
	assert v.get_dot_path(bad.issues[0]) == 'name'
	cross := v.partial_check(schema, [[types.PathSegment('password')],
		[types.PathSegment('confirm')]], fn (a Account) bool {
		return a.password == a.confirm
	}, 'Passwords differ')
	result := support.observe(cross, Account{ name: 'a', age: 1, password: 'a', confirm: 'b' })
	assert result.issues.map(it.code) == ['min_length', 'partial_check']
}

fn test_cache_capacity_and_configuration_are_part_of_key() {
	schema := v.cache(v.pipe(v.string(), v.min_length(3), v.starts_with('x')), fn (s string) string {
		return s
	}, max_size: 2)
	for value in ['abc', 'x', 'xyz', 'abc', 'x', 'xyz'] {
		output := support.observe(schema, value)
		assert output.success == (value == 'xyz')
	}
	assert support.observe(schema, 'a', v.Config{ abort_early: true }).issues.len == 1
	assert support.observe(schema, 'a').issues.len == 2
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
	}, max_size: 2)
	for input in ['a', 'a', 'b', 'a', 'c', 'b'] {
		v.parse(cached, input) or { panic(err) }
	}
	assert calls.value == 4
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
	uncached := v.cache(schema, fn (input string) string {
		return input
	}, v.CacheConfig{ max_size: 0 })
	for _ in 0 .. 2 {
		v.parse(uncached, 'x') or { panic(err) }
	}
	assert clock.calls == 5
}
