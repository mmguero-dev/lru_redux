class LruReredux::ThreadSafeCache < LruReredux::Cache
  include LruReredux::Util::SafeSync
end
