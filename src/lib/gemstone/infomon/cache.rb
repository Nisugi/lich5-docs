# Namespace module for the Lich application
module Lich
  # Namespace module for Gemstone-specific functionality
  module Gemstone
    # Module containing information monitoring functionality
    module Infomon
      # In-memory cache implementation with support for lazy loading values.
      # Provides a simple key-value store with cache miss handling.
      #
      # @author Lich5 Documentation Generator
      class Cache
        # Hash containing the cached key-value pairs
        # @return [Hash] The internal cache storage
        attr_reader :records

        # Initializes a new empty cache
        #
        # @return [Cache] A new Cache instance with empty storage
        # @example
        #   cache = Cache.new
        def initialize()
          @records = {}
        end

        # Stores a value in the cache under the specified key
        #
        # @param key [Object] The key to store the value under
        # @param value [Object] The value to cache
        # @return [Cache] Returns self for method chaining
        # @example
        #   cache.put(:key, "value")
        def put(key, value)
          @records[key] = value
          self
        end

        # Checks if a key exists in the cache
        #
        # @param key [Object] The key to check for
        # @return [Boolean] true if key exists, false otherwise
        # @example
        #   cache.include?(:key) #=> true/false
        def include?(key)
          @records.include?(key)
        end

        # Removes all entries from the cache
        #
        # @return [void]
        # @example
        #   cache.flush!
        def flush!
          @records.clear
        end

        # Removes a specific key-value pair from the cache
        #
        # @param key [Object] The key to remove
        # @return [Object, nil] The removed value, or nil if key didn't exist
        # @example
        #   cache.delete(:key)
        def delete(key)
          @records.delete(key)
        end

        # Retrieves a value from the cache, computing it if not present
        #
        # @param key [Object] The key to look up
        # @yield [key] Block to compute value on cache miss
        # @return [Object, nil] The cached or computed value
        # @note Nil values are not cached
        # @example
        #   cache.get(:key) { |k| compute_value(k) }
        def get(key)
          return @records[key] if self.include?(key)
          miss = nil
          miss = yield(key) if block_given?
          # don't cache nils
          return miss if miss.nil?
          @records[key] = miss
        end

        # Merges another hash into the cache
        #
        # @param h [Hash] The hash to merge into the cache
        # @return [Hash] The updated cache contents
        # @example
        #   cache.merge!({key: "value"})
        def merge!(h)
          @records.merge!(h)
        end

        # Converts the cache contents to an array of key-value pairs
        #
        # @return [Array<Array>] Array of [key, value] pairs
        # @example
        #   cache.to_a #=> [[:key1, "val1"], [:key2, "val2"]]
        def to_a()
          @records.to_a
        end

        # Returns the cache contents as a hash
        #
        # @return [Hash] Hash containing all cached key-value pairs
        # @example
        #   cache.to_h #=> {key1: "val1", key2: "val2"}
        def to_h()
          @records
        end

        # Alias for {#flush!}
        # @see #flush!
        alias :clear :flush!

        # Alias for {#include?}
        # @see #include?
        alias :key? :include?
      end
    end
  end
end