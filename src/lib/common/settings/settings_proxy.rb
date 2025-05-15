module Lich
  module Common
    # This module provides a proxy class for settings objects, allowing them to be accessed
    # in a Ruby-compatible way. It handles both scalar and container types, and
    # provides methods for comparison, conversion, and enumeration.
    #
    # The proxy is designed to work with settings objects that are either Hashes or Arrays.
    # It allows for nested access to settings, while also providing a way to save changes
    # made to the settings.
    #
    # The proxy also provides a way to handle non-destructive methods, which return a new
    # object instead of modifying the original. This is done by creating a duplicate of the
    # target object before calling the method, and then returning a new proxy for the result
    # if it is a container type.
    #
    # The proxy also handles method delegation, allowing methods to be called directly on
    # the target object. It uses method_missing to catch calls to methods that are not
    # defined on the proxy itself, and delegates them to the target object.
    #
    # The proxy also provides a way to handle results of non-destructive methods, which
    # return a new object instead of modifying the original. This is done by creating a
    # duplicate of the target object before calling the method, and then returning a new
    # proxy for the result if it is a container type.

    class SettingsProxy
      # Initializes a new SettingsProxy instance.
      #
      # @param settings [Object] The settings object being proxied.
      # @param path [Array] The path to the current settings.
      # @param target [Object] The target object being proxied.
      def initialize(settings, path, target)
        @settings = settings
        @path = path.dup
        @target = target
      end

      # Allow access to the target for debugging
      #
      # @return [Object] The target object.
      attr_reader :target, :path

      #
      # Standard Ruby methods
      #

      # Checks if the target is nil.
      #
      # @return [Boolean] True if the target is nil, false otherwise.
      def nil?
        @target.nil?
      end

      # Helper method for binary operators to reduce repetition.
      #
      # @param operator [Symbol] The binary operator to apply.
      # @param other [Object] The other operand.
      # @return [Object] The result of the binary operation.
      def binary_op(operator, other)
        other_value = other.is_a?(SettingsProxy) ? other.target : other
        @target.send(operator, other_value)
      end

      # Define comparison operators using metaprogramming to reduce repetition.
      # NB: not all operators apply to all objects (e.g. <, >, <=, >= on Arrays).
      #
      # @return [Boolean] The result of the comparison.
      [:==, :!=, :eql?, :equal?, :<=>, :<, :<=, :>, :>=, :|, :&].each do |op|
        define_method(op) do |other|
          binary_op(op, other)
        end
      end

      # Returns the hash code of the target.
      #
      # @return [Integer] The hash code of the target.
      def hash
        @target.hash
      end

      # Returns a string representation of the target.
      #
      # @return [String] The string representation of the target.
      def to_s
        @target.to_s
      end

      # Returns a string representation of the target for debugging.
      #
      # @return [String] The inspected string representation of the target.
      def inspect
        @target.inspect
      end

      # Pretty prints the target.
      #
      # @param pp [Object] The pretty print object.
      # @return [void]
      def pretty_print(pp)
        pp.pp(@target)
      end

      #
      # Type checking methods
      #

      # Checks if the target is an instance of the given class.
      #
      # @param klass [Class] The class to check against.
      # @return [Boolean] True if the target is an instance of the class, false otherwise.
      def is_a?(klass)
        @target.is_a?(klass)
      end

      # Checks if the target is a kind of the given class.
      #
      # @param klass [Class] The class to check against.
      # @return [Boolean] True if the target is a kind of the class, false otherwise.
      def kind_of?(klass)
        @target.kind_of?(klass)
      end

      # Checks if the target is an instance of the given class.
      #
      # @param klass [Class] The class to check against.
      # @return [Boolean] True if the target is an instance of the class, false otherwise.
      def instance_of?(klass)
        @target.instance_of?(klass)
      end

      # Checks if the target responds to the given method.
      #
      # @param method [Symbol] The method name to check.
      # @param include_private [Boolean] Whether to include private methods in the check.
      # @return [Boolean] True if the target responds to the method, false otherwise.
      def respond_to?(method, include_private = false)
        super || @target.respond_to?(method, include_private)
      end

      #
      # Conversion methods
      #

      # Converts the target to a hash.
      #
      # @return [Hash, nil] A duplicate of the target if it is a Hash, nil otherwise.
      def to_hash
        return nil unless @target.is_a?(Hash)

        @target.dup
      end

      # Converts the target to a hash (alias for to_hash).
      #
      # @return [Hash, nil] A duplicate of the target if it is a Hash, nil otherwise.
      def to_h
        to_hash
      end

      # Converts the target to an array.
      #
      # @return [Array, nil] A duplicate of the target if it is an Array, nil otherwise.
      def to_ary
        return nil unless @target.is_a?(Array)

        @target.dup
      end

      # Converts the target to an array (alias for to_ary).
      #
      # @return [Array, nil] A duplicate of the target if it is an Array, nil otherwise.
      def to_a
        to_ary
      end

      # Define conversion methods using metaprogramming to reduce repetition.
      #
      # @return [Object] The result of the conversion method.
      [:to_int, :to_i, :to_str, :to_sym, :to_proc].each do |method|
        define_method(method) do
          @target.send(method) if @target.respond_to?(method)
        end
      end

      #
      # Enumerable support
      #

      # Iterates over each item in the target.
      #
      # @yield [Object] The block to execute for each item.
      # @return [self] The SettingsProxy instance.
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

      # Non-destructive enumerable methods that should not save changes.
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

      # Accesses a value in the target by key.
      #
      # @param key [Object] The key to access the value.
      # @return [Object] The value associated with the key, or a new SettingsProxy if the value is a container.
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

      # Sets a value in the target by key.
      #
      # @param key [Object] The key to set the value.
      # @param value [Object] The value to set.
      # @return [Object] The value that was set.
      def []=(key, value)
        @target[key] = value
        @settings.save_proxy_changes(self)
        # value
      end

      #
      # Method delegation
      #

      # Handles method calls that are not defined on the proxy.
      #
      # @param method [Symbol] The method name to call.
      # @param args [Array] The arguments to pass to the method.
      # @param block [Proc] The block to pass to the method.
      # @return [Object] The result of the method call.
      # @raise [NoMethodError] If the method is not defined on the target.
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

      # Helper method to handle results of non-destructive methods.
      #
      # @param result [Object] The result of the non-destructive method.
      # @return [Object] The wrapped result in a new SettingsProxy if it's a container, or the result itself.
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

      # Helper method to handle results of destructive methods.
      #
      # @param result [Object] The result of the destructive method.
      # @return [Object] The wrapped result in a new SettingsProxy if it's a container, or the result itself.
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

      # Checks if the target responds to the given method.
      #
      # @param method [Symbol] The method name to check.
      # @param include_private [Boolean] Whether to include private methods in the check.
      # @return [Boolean] True if the target responds to the method, false otherwise.
      def respond_to_missing?(method, include_private = false)
        @target.respond_to?(method, include_private) || super
      end
    end
  end
end