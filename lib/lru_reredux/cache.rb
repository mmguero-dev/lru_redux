# Ruby 1.9 makes our life easier, Hash is already ordered
#
# This is an ultra efficient 1.9 friendly implementation
class LruReredux::Cache
  attr_reader :max_size, :getset_ignores_nil

  def initialize(max_size = 2048, getset_ignores_nil = false)

    getset_ignores_nil = false if getset_ignores_nil.nil?

    raise ArgumentError.new(:max_size) if
        max_size < 1
    raise ArgumentError.new(:getset_ignores_nil) unless
        [true, false].include?(getset_ignores_nil)

    @max_size = max_size
    @getset_ignores_nil = getset_ignores_nil
    @data = {}
  end

  def max_size=(max_size)
    max_size ||= @max_size

    raise ArgumentError.new(:max_size) if max_size < 1

    @max_size = max_size

    @data.shift while @data.size > @max_size
  end

  def ttl=(_)
    nil
  end

  def getset_ignores_nil=(getset_ignores_nil)
    getset_ignores_nil ||= @getset_ignores_nil

    raise ArgumentError.new(:getset_ignores_nil) unless
        [true, false].include?(getset_ignores_nil)

    @getset_ignores_nil = getset_ignores_nil
  end

  def getset(key)
    found = true
    value = @data.delete(key){ found = false }
    if found
      @data[key] = value
    else
      result = yield
      if !result.nil? || !@getset_ignores_nil
        @data[key] = result
        @data.shift if @data.length > @max_size
      end
      result
    end
  end

  def fetch(key)
    found = true
    value = @data.delete(key){ found = false }
    if found
      @data[key] = value
    else
      yield if block_given?
    end
  end

  def [](key)
    found = true
    value = @data.delete(key){ found = false }
    if found
      @data[key] = value
    else
      nil
    end
  end

  def []=(key,val)
    @data.delete(key)
    @data[key] = val
    @data.shift if @data.length > @max_size
    val
  end

  def each
    array = @data.to_a
    array.reverse!.each do |pair|
      yield pair
    end
  end

  # used further up the chain, non thread safe each
  alias_method :each_unsafe, :each

  def to_a
    array = @data.to_a
    array.reverse!
  end

  def values
    vals = @data.values
    vals.reverse!
  end

  def delete(key)
    @data.delete(key)
  end

  alias_method :evict, :delete

  def key?(key)
    @data.key?(key)
  end

  alias_method :has_key?, :key?

  def clear
    @data.clear
  end

  def count
    @data.size
  end

  protected

  # for cache validation only, ensures all is sound
  def valid?
    true
  end
end
