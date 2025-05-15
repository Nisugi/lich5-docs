# A module containing common functionality for the Lich system
module Lich
  module Common
    # A proxy class that provides Ruby-compatible access to settings objects.
    # Handles both scalar and container types (Hash, Array) with support for
    # nested access, comparison operations, and enumeration.
    #
    # @author Lich5 Documentation Generator
    class SettingsProxy
      # Creates a new settings proxy instance
      #
      # @param settings [Object] The parent settings object
      # @param path [Array] The path to this setting in the hierarchy
      # @param target [Object] The actual value being proxied
      # @return [SettingsProxy] A new proxy instance
      def initialize(settings, path, target)
        @settings = settings
        @path = path.dup
        @target = target
      end

      # @return [Object] The underlying target object being proxied
      # @return [Array] The path to this setting in the hierarchy
      attr_reader :target, :path

      #
      # Standard Ruby methods
      #

      # Checks if the proxied value is nil
      #
      # @return [Boolean] true if the target is nil, false otherwise
      # @example
      #   settings.some_value.nil? #=> true/false
      def nil?
        @target.nil?
      end

      # Helper method for implementing binary operators
      #
      # @param operator [Symbol] The operator method name
      # @param other [Object] The other operand
      # @return [Object] Result of the operation
      # @api private
      def binary_op(operator, other)
        other_value = other.is_a?(SettingsProxy) ? other.target : other
        @target.send(operator, other_value)
      end

      # Define comparison operators using metaprogramming to reduce repetition
      # NB: not all operators apply to all objects (e.g. <, >, <=, >= on Arrays)
      [:==, :!=, :eql?, :equal?, :<=>, :<, :<=, :>, :>=, :|, :&].each do |op|
        define_method(op) do |other|
          binary_op(op, other)
        end
      end

      def hash
        @target.hash
      end

      def to_s
        @target.to_s
      end

      def inspect
        @target.inspect
      end

      def pretty_print(pp)
        pp.pp(@target)
      end

      #
      # Type checking methods
      #

      def is_a?(klass)
        @target.is_a?(klass)
      end

      def kind_of?(klass)
        @target.kind_of?(klass)
      end

      def instance_of?(klass)
        @target.instance_of?(klass)
      end

      def respond_to?(method, include_private = false)
        super || @target.respond_to?(method, include_private)
      end

      #
      # Conversion methods
      #

      # Converts the proxied value to a hash if possible
      #
      # @return [Hash, nil] A copy of the target hash or nil if not a Hash
      # @example
      #   settings.hash_value.to_hash #=> {"key" => "value"}
      def to_hash
        return nil unless @target.is_a?(Hash)

        @target.dup
      end

      def to_h
        to_hash
      end

      # Converts the proxied value to an array if possible
      #
      # @return [Array, nil] A copy of the target array or nil if not an Array
      # @example
      #   settings.array_value.to_ary #=> [1, 2, 3]
      def to_ary
        return nil unless @target.is_a?(Array)

        @target.dup
      end

      def to_a
        to_ary
      end

      # Define conversion methods using metaprogramming to reduce repetition
      [:to_int, :to_i, :to_str, :to_sym, :to_proc].each do |method|
        define_method(method) do
          @target.send(method) if @target.respond_to?(method)
        end
      end

      #
      # Enumerable support
      #

      # Implements enumerable functionality for container types
      #
      # @yield [Object] Each element in the container
      # @return [Enumerator] If no block given
      # @return [self] If block given
      # @example
      #   settings.array_value.each { |item| puts item }
      def each(&_block)
        return enum_for(:each) unless block_given?

        if @target.respond_to?(:each)
          @target.each do |item|
            if Settings.container?(item)
              yield SettingsProxy.new(@settings, [], item)
            else
              yield item
            end
          end
        end

        self
      end

      # List of methods that should not trigger settings persistence
      #
      # @return [Array<Symbol>] Method names that are considered non-destructive
      NON_DESTRUCTIVE_METHODS = [
        :select, :map, :filter, :reject, :collect, :find, :detect,
        :find_all, :grep, :grep_v, :group_by, :partition, :min, :max,
        :minmax, :min_by, :max_by, :minmax_by, :sort, :sort_by,
        :flat_map, :collect_concat, :reduce, :inject, :sum, :count,
        :cycle, :drop, :drop_while, :take, :take_while, :first, :all?,
        :any?, :none?, :one?, :find_index, :values_at, :zip, :reverse,
        :entries, :to_a, :to_h, :include?, :member?, :each_with_index,
        :each_with_object, :each_entry, :each_slice, :each_cons, :chunk,
        :slice_before, :slice_after, :slice_when, :chunk_while, :lazy
      ].freeze

      #
      # Container access
      #

      # Accesses elements in container types
      #
      # @param key [Object] The key/index to access
      # @return [Object, SettingsProxy] The value or a proxy for nested containers
      # @example
      #   settings.hash_value["key"]
      #   settings.array_value[0]
      def [](key)
        value = @target[key]

        if Settings.container?(value)
          # For container types, return a new proxy with updated path
          new_path = @path.dup
          new_path << key
          SettingsProxy.new(@settings, new_path, value)
        else
          # For scalar values, return the value directly
          value
        end
      end

      # Sets values in container types
      #
      # @param key [Object] The key/index to set
      # @param value [Object] The value to set
      # @return [Object] The set value
      # @example
      #   settings.hash_value["key"] = "new value"
      def []=(key, value)
        @target[key] = value
        @settings.save_proxy_changes(self)
        # value
      end

      #
      # Method delegation
      #

      # Handles method delegation to the target object
      #
      # @param method [Symbol] The method name
      # @param args [Array] Method arguments
      # @param block [Proc] Optional block
      # @return [Object] Result of the method call
      # @raise [NoMethodError] If method doesn't exist on target
      def method_missing(method, *args, &block)
        if @target.respond_to?(method)
          # For non-destructive methods, operate on a duplicate to avoid modifying original
          if NON_DESTRUCTIVE_METHODS.include?(method)
            # Create a duplicate of the target for non-destructive operations
            target_dup = @target.dup
            result = target_dup.send(method, *args, &block)

            # Return the result without saving changes
            return handle_non_destructive_result(result)
          else
            # For destructive methods, operate on the original and save changes
            result = @target.send(method, *args, &block)
            @settings.save_proxy_changes(self)
            return handle_method_result(result)
          end
        else
          super
        end
      end

      # Handles results from non-destructive method calls
      #
      # @param result [Object] The result to process
      # @return [Object, SettingsProxy] Processed result
      # @api private
      def handle_non_destructive_result(result)
        # No need to capture path since we're using empty path
        @settings.reset_path_and_return(
          if Settings.container?(result)
            # For container results, wrap in a new proxy with empty path
            SettingsProxy.new(@settings, [], result)
          else
            # For scalar results, return directly
            result
          end
        )
      end

      # Handles results from destructive method calls
      #
      # @param result [Object] The result to process
      # @return [Object, SettingsProxy] Processed result
      # @api private
      def handle_method_result(result)
        if result.equal?(@target)
          # If result is the original target, return self
          self
        elsif Settings.container?(result)
          # For container results, wrap in a new proxy with current path
          SettingsProxy.new(@settings, @path, result)
        else
          # For scalar results, return directly
          result
        end
      end

      # Checks if a method can be handled by method_missing
      #
      # @param method [Symbol] Method name to check
      # @param include_private [Boolean] Whether to include private methods
      # @return [Boolean] true if method can be handled
      def respond_to_missing?(method, include_private = false)
        @target.respond_to?(method, include_private) || super
      end
    end
  end
end