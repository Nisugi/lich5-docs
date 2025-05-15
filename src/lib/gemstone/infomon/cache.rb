module Lich
  module Gemstone
    module Infomon
      # in-memory cache with db read fallbacks
      #
      # This class provides a simple in-memory cache that allows for storing,
      # retrieving, and managing key-value pairs. It also supports fallback
      # mechanisms for retrieving values when they are not present in the cache.
      class Cache
        attr_reader :records

        # Initializes a new Cache instance.
        #
        # @return [Cache] the newly created Cache instance.
        def initialize()
          @records = {}
        end

        # Stores a value in the cache associated with a given key.
        #
        # @param key [Object] the key to associate with the value.
        # @param value [Object] the value to store in the cache.
        # @return [Cache] the Cache instance for method chaining.
        #
        # @example
        #   cache = Cache.new
        #   cache.put(:foo, 'bar')
        def put(key, value)
          @records[key] = value
          self
        end

        # Checks if a key exists in the cache.
        #
        # @param key [Object] the key to check for existence.
        # @return [Boolean] true if the key exists, false otherwise.
        #
        # @example
        #   cache = Cache.new
        #   cache.put(:foo, 'bar')
        #   cache.include?(:foo) # => true
        def include?(key)
          @records.include?(key)
        end

        # Clears all records from the cache.
        #
        # @return [void]
        #
        # @example
        #   cache = Cache.new
        #   cache.put(:foo, 'bar')
        #   cache.flush! # clears the cache
        def flush!
          @records.clear
        end

        # Deletes a key-value pair from the cache.
        #
        # @param key [Object] the key to delete from the cache.
        # @return [Object, nil] the value associated with the key, or nil if the key was not found.
        #
        # @example
        #   cache = Cache.new
        #   cache.put(:foo, 'bar')
        #   cache.delete(:foo) # => 'bar'
        def delete(key)
          @records.delete(key)
        end

        # Retrieves a value from the cache, or computes it using a block if not present.
        #
        # @param key [Object] the key to retrieve from the cache.
        # @return [Object, nil] the value associated with the key, or nil if not found and block returns nil.
        #
        # @yield [key] a block to compute the value if it is not present in the cache.
        #
        # @example
        #   cache = Cache.new
        #   value = cache.get(:foo) { 'default' } # => 'default'
        def get(key)
          return @records[key] if self.include?(key)
          miss = nil
          miss = yield(key) if block_given?
          # don't cache nils
          return miss if miss.nil?
          @records[key] = miss
        end

        # Merges another hash into the cache.
        #
        # @param h [Hash] the hash to merge into the cache.
        # @return [Hash] the updated records hash.
        #
        # @example
        #   cache = Cache.new
        #   cache.merge!({foo: 'bar', baz: 'qux'}) # merges the hash into the cache
        def merge!(h)
          @records.merge!(h)
        end

        # Converts the cache records to an array of key-value pairs.
        #
        # @return [Array] an array of key-value pairs.
        #
        # @example
        #   cache = Cache.new
        #   cache.put(:foo, 'bar')
        #   cache.to_a # => [[:foo, 'bar']]
        def to_a()
          @records.to_a
        end

        # Converts the cache records to a hash.
        #
        # @return [Hash] the hash of records.
        #
        # @example
        #   cache = Cache.new
        #   cache.put(:foo, 'bar')
        #   cache.to_h # => {:foo => 'bar'}
        def to_h()
          @records
        end

        alias :clear :flush!
        alias :key? :include?
      end
    end
  end
end