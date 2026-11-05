module methods

import sync
import time
import valibro.types

@[params]
pub struct CacheConfig {
pub:
	max_size int = 1000
	// None is unlimited; expiration is strictly greater than max_age_ms.
	max_age_ms ?i64
	now        fn () i64 = fn () i64 {
		return time.now().unix_milli()
	}
}

struct CacheState[O] {
mut:
	mutex      sync.Mutex
	entries    map[string]types.Dataset[O]
	timestamps map[string]i64
	order      []string
}

pub struct CachedSchema[I, O] {
pub:
	schema       types.Schema[I, O]
	config       CacheConfig
	key_function fn (I) string  @[required]
	state        &CacheState[O] @[required]
}

pub fn (cached CachedSchema[I, O]) key(input I, config types.Config) string {
	return cached.key_function(input) + '|' + config.str()
}

pub fn (cached CachedSchema[I, O]) get(key string) ?types.Dataset[O] {
	mut state := cached.state
	return cache_get[O](mut state, cached.config, key)
}

fn cache_get[O](mut state CacheState[O], config CacheConfig, key string) ?types.Dataset[O] {
	state.mutex.lock()
	defer { state.mutex.unlock() }
	if key !in state.entries { return none }
	if age := config.max_age_ms {
		if config.now() - state.timestamps[key] > age {
			state.entries.delete(key)
			state.timestamps.delete(key)
			index := state.order.index(key)
			if index >= 0 { state.order.delete(index) }
			return none
		}
	}
	index := state.order.index(key)
	if index >= 0 { state.order.delete(index) }
	state.order << key
	hit := state.entries[key] or { return none }
	return types.Dataset[O]{
		...hit
		issues: hit.issues.clone()
	}
}

pub fn (cached CachedSchema[I, O]) set(key string, value types.Dataset[O]) {
	mut state := cached.state
	cache_set[O](mut state, cached.config, key, value)
}

fn cache_set[O](mut state CacheState[O], config CacheConfig, key string, value types.Dataset[O]) {
	state.mutex.lock()
	defer { state.mutex.unlock() }
	index := state.order.index(key)
	if index >= 0 { state.order.delete(index) }
	state.order << key
	state.entries[key] = types.Dataset[O]{
		...value
		issues: value.issues.clone()
	}
	state.timestamps[key] = if config.max_age_ms != none { config.now() } else { i64(0) }
	if state.order.len > config.max_size {
		oldest := state.order[0]
		state.order.delete(0)
		state.entries.delete(oldest)
		state.timestamps.delete(oldest)
	}
}

pub fn (cached CachedSchema[I, O]) clear() {
	mut state := cached.state
	state.mutex.lock()
	defer { state.mutex.unlock() }
	state.entries.clear()
	state.timestamps.clear()
	state.order.clear()
}

// Explicit keys make native input value/reference identity a caller decision.
pub fn cached[I, O](schema types.Schema[I, O], key fn (I) string, config CacheConfig) CachedSchema[I, O] {
	assert config.max_size >= 0, 'Cache size must be non-negative'
	mut state := &CacheState[O]{}
	wrapped := types.Schema[I, O]{
		...schema
		run: fn [schema, key, config, mut state] [I, O](input I, settings types.Config) types.Dataset[O] {
			if contains_message_callback(settings) {
				return types.run[I, O](schema, input, settings)
			}
			cache_key := key(input) + '|' + settings.str()
			if hit := cache_get[O](mut state, config, cache_key) { return hit }
			result := types.run[I, O](schema, input, settings)
			if result.exception != none { return result }
			cache_set[O](mut state, config, cache_key, result)
			return types.Dataset[O]{
				...result
				issues: result.issues.clone()
			}
		}
	}
	return CachedSchema[I, O]{
		schema:       wrapped
		config:       config
		key_function: key
		state:        state
	}
}

fn contains_message_callback(config types.Config) bool {
	if message := config.message {
		if unidentified_message(message) { return true }
	}
	for _, message in config.messages.defaults {
		if unidentified_message(message) { return true }
	}
	for _, message in config.messages.schema {
		if unidentified_message(message) { return true }
	}
	for _, messages in config.messages.specific {
		for _, message in messages {
			if unidentified_message(message) { return true }
		}
	}
	return false
}

fn unidentified_message(message types.ErrorMessage) bool {
	if message is types.MessageFunction { return true }
	if message is types.MessageCallback { return message.cache_identity() == '' }
	return false
}

pub fn cache[I, O](schema types.Schema[I, O], key fn (I) string, config CacheConfig) types.Schema[I, O] {
	return cached[I, O](schema, key, config).schema
}
