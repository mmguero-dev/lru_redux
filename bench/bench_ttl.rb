require 'bundler'
require 'benchmark'
require 'fast_cache'

Bundler.require

# FastCache
fast_cache = FastCache::Cache.new(1_000, 5 * 60)

# LruReredux
redux_ttl = LruReredux::TTL::Cache.new(1_000, 5 * 60)
redux_ttl_thread_safe = LruReredux::TTL::ThreadSafeCache.new(1_000, 5 * 60)
redux_ttl_disabled = LruReredux::TTL::Cache.new(1_000, :none)

puts
puts "** TTL Benchmarks **"
Benchmark.bmbm do |bm|
  bm.report 'FastCache' do
    1_000_000.times { fast_cache.fetch(rand(2_000)) { :value } }
  end

  bm.report 'LruReredux::TTL::Cache' do
    1_000_000.times { redux_ttl.getset(rand(2_000)) { :value } }
  end

  bm.report 'LruReredux::TTL::ThreadSafeCache' do
    1_000_000.times { redux_ttl_thread_safe.getset(rand(2_000)) { :value } }
  end

  bm.report 'LruReredux::TTL::Cache (TTL disabled)' do
    1_000_000.times { redux_ttl_disabled.getset(rand(2_000)) { :value } }
  end
end