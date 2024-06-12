class LruReredux::TTL::ThreadSafeCache < LruReredux::TTL::Cache
  include LruReredux::Util::SafeSync
end
