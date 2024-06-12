# LruReredux [![Gem Version](https://badge.fury.io/rb/lru_reredux.svg)](http://badge.fury.io/rb/lru_reredux)
An efficient, thread safe LRU cache. Forked from [LruRedux](https://github.com/SamSaffron/lru_redux) which was last updated in 2017.

- [Installation](#installation)
- [Usage](#usage)
  - [TTL Cache](#ttl-cache)
- [Cache Methods](#cache-methods)
- [Benchmarks](#benchmarks)
- [Other Caches](#other-caches)
- [Contributing](#contributing)
- [Changelog](#changelog)

## Installation

Add this line to your application's Gemfile:

    gem 'lru_reredux'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lru_reredux

## Usage

```ruby
require 'lru_reredux'

# non thread safe
cache = LruReredux::Cache.new(100)
cache[:a] = "1"
cache[:b] = "2"

cache.to_a
# [[:b,"2"],[:a,"1"]]
# note the order matters here, last accessed is first

cache[:a] # a pushed to front
# "1"

cache.to_a
# [[:a,"1"],[:b,"2"]]
cache.delete(:a)
cache.each {|k,v| p "#{k} #{v}"}
# b 2

cache.max_size = 200 # cache now stores 200 items
cache.clear # cache has no items

cache.getset(:a){1}
cache.to_a
#[[:a,1]]

# already set so don't call block
cache.getset(:a){99}
cache.to_a
#[[:a,1]]

# for thread safe access, all methods on cache
# are protected with a mutex
cache = LruReredux::ThreadSafeCache.new(100)

```

#### TTL Cache
The TTL cache extends the functionality of the LRU cache with a Time To Live eviction strategy. TTL eviction occurs on every access and takes precedence over LRU eviction, meaning a 'live' value will never be evicted over an expired one.

```ruby
# Timecop is gem that allows us to change Time.now
# and is used for demonstration purposes.
require 'lru_reredux'
require 'timecop'

# Create a TTL cache with a size of 100 and TTL of 5 minutes.
# The first argument is the size and
# the second optional argument is the TTL in seconds.
cache = LruReredux::TTL::Cache.new(100, 5 * 60)

Timecop.freeze(Time.now)

cache[:a] = "1"
cache[:b] = "2"

cache.to_a
# => [[:b,"2"],[:a,"1"]]

# Now we advance time 5 min 30 sec into the future.
Timecop.freeze(Time.now + 330)

# And we see that the expired values have been evicted.
cache.to_a
# => []

# The TTL can be updated on a live cache using #ttl=.
# Currently cached items will be evicted under the new TTL.
cache[:a] = "1"
cache[:b] = "2"

Timecop.freeze(Time.now + 330)

cache.ttl = 10 * 60

# Since ttl eviction is triggered by access,
# the items are still cached when the ttl is changed and
# are now under the 10 minute TTL.
cache.to_a
# => [[:b,"2"],[:a,"1"]]

# TTL eviction can be triggered manually with the #expire method.
Timecop.freeze(Time.now + 330)

cache.expire
cache.to_a
# => []

Timecop.return

# The behavior of a TTL cache with the TTL set to `:none`
# is identical to the LRU cache.

cache = LruReredux::TTL::Cache.new(100, :none)

# The TTL argument is optional and defaults to `:none`.
cache = LruReredux::TTL::Cache.new(100)

# A thread safe version is available.
cache = LruReredux::TTL::ThreadSafeCache.new(100, 5 * 60)
```

## Cache Methods
- `#getset` Takes a key and block.  Will return a value if cached, otherwise will execute the block and cache the resulting value.
- `#fetch` Takes a key and optional block.  Will return a value if cached, otherwise will execute the block and return the resulting value or return nil if no block is provided.
- `#[]` Takes a key.  Will return a value if cached, otherwise nil.
- `#[]=` Takes a key and value. Will cache the value under the key.
- `#delete` Takes a key.  Will return the deleted value, otherwise nil.
- `#evict` Alias for `#delete`.
- `#clear` Clears the cache. Returns nil.
- `#each` Takes a block.  Executes the block on each key-value pair in LRU order (most recent first).
- `#to_a` Return an array of key-value pairs (arrays) in LRU order (most recent first).
- `#key?` Takes a key.  Returns true if the key is cached, otherwise false.
- `#has_key?` Alias for `#key?`.
- `#count` Return the current number of items stored in the cache.
- `#max_size` Returns the current maximum size of the cache.
- `#max_size=` Takes a positive number.  Changes the current max_size and triggers a resize.  Also triggers TTL eviction on the TTL cache.

#### TTL Cache Specific
- `#ttl` Returns the current TTL of the cache.
- `#ttl=` Takes `:none` or a positive number.  Changes the current ttl and triggers a TTL eviction.
- `#expire` Triggers a TTL eviction.

## Benchmarks

see: benchmark directory (a million random lookup / store)

#### LRU
##### Ruby 2.2.1
```
$ ruby ./bench/bench.rb

Rehearsal -------------------------------------------------------------
ThreadSafeLru               4.500000   0.030000   4.530000 (  4.524213)
LRU                         2.250000   0.000000   2.250000 (  2.249670)
LRUCache                    1.720000   0.010000   1.730000 (  1.728243)
LruReredux::Cache           0.960000   0.000000   0.960000 (  0.961292)
LruReredux::ThreadSafeCache 2.180000   0.000000   2.180000 (  2.187714)
--------------------------------------------------- total: 11.650000sec

                                user     system      total        real
ThreadSafeLru               4.390000   0.020000   4.410000 (  4.415703)
LRU                         2.140000   0.010000   2.150000 (  2.149626)
LRUCache                    1.680000   0.010000   1.690000 (  1.688564)
LruReredux::Cache           0.910000   0.000000   0.910000 (  0.913108)
LruReredux::ThreadSafeCache 2.200000   0.010000   2.210000 (  2.212108)
```

#### TTL
##### Ruby 2.2.1
```
$ ruby ./bench/bench_ttl.rb
Rehearsal -----------------------------------------------------------------------
FastCache                             6.240000   0.070000   6.310000 (  6.302569)
LruReredux::TTL::Cache                4.700000   0.010000   4.710000 (  4.712858)
LruReredux::TTL::ThreadSafeCache      6.300000   0.010000   6.310000 (  6.319032)
LruReredux::TTL::Cache (TTL disabled) 2.460000   0.010000   2.470000 (  2.470629)
------------------------------------------------------------- total: 19.800000sec

                                          user     system      total        real
FastCache                             6.470000   0.070000   6.540000 (  6.536193)
LruReredux::TTL::Cache                4.640000   0.010000   4.650000 (  4.661793)
LruReredux::TTL::ThreadSafeCache      6.310000   0.020000   6.330000 (  6.328840)
LruReredux::TTL::Cache (TTL disabled) 2.440000   0.000000   2.440000 (  2.446269)
```

## Other Caches
This is a list of the caches that are used in the benchmarks.

#### LruRedux (from which LruReredux is forked)
- RubyGems: https://rubygems.org/gems/lru_redux
- Homepage: https://github.com/SamSaffron/lru_redux

#### LRU
- RubyGems: https://rubygems.org/gems/lru
- Homepage: http://lru.rubyforge.org/

#### LRUCache
- RubyGems: https://rubygems.org/gems/lru_cache
- Homepage: https://github.com/brendan/lru_cache

#### ThreadSafeLru
- RubyGems: https://rubygems.org/gems/threadsafe-lru
- Homepage: https://github.com/draganm/threadsafe-lru

#### FastCache
- RubyGems: https://rubygems.org/gems/fast_cache
- Homepage: https://github.com/swoop-inc/fast_cache


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Changelog
### version 1.2.0 - 12-Jun-2024

- New: Added getset_ignores_nil argument to cache initialize arguments. If true, blocks called by getset yielding nil values will be returned but not stored in the cache. Ruby >= 2.1.0 is required for LruReredux.

See [LruRedux](https://github.com/SamSaffron/lru_redux) for changes made prior to the creation of this fork.