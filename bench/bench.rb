require 'bundler'
require 'benchmark'
require 'lru'
require 'lru_cache'
require 'threadsafe-lru'

Bundler.require

# Lru
lru = Cache::LRU.new(max_elements: 1_000)

# LruCache
lru_cache = LRUCache.new(1_000)

# ThreadSafeLru
thread_safe_lru = ThreadSafeLru::LruCache.new(1_000)

# LruReredux
redux = LruReredux::Cache.new(1_000)
redux_thread_safe = LruReredux::ThreadSafeCache.new(1_000)

puts "** LRU Benchmarks **"
Benchmark.bmbm do |bm|
  bm.report 'ThreadSafeLru' do
    1_000_000.times { thread_safe_lru.get(rand(2_000)) { :value } }
  end

  bm.report 'LRU' do
    1_000_000.times { lru[rand(2_000)] ||= :value }
  end

  bm.report 'LRUCache' do
    1_000_000.times { lru_cache[rand(2_000)] ||= :value }
  end

  bm.report 'LruReredux::Cache' do
    1_000_000.times { redux.getset(rand(2_000)) { :value } }
  end

  bm.report 'LruReredux::ThreadSafeCache' do
    1_000_000.times { redux_thread_safe.getset(rand(2_000)) { :value } }
  end
end
