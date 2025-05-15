# Extensions to the Ruby Hash class to provide additional functionality
#
# @author Lich5 Documentation Generator
class Hash

  # Creates or updates a nested hash value using a path array
  #
  # @param target [Hash] The hash to modify
  # @param path [Array, Object] The path to the value, either as array of keys or single key
  # @param val [Object] The value to set at the specified path
  # @return [Hash] The modified target hash
  # @raise [ArgumentError] If the path is empty
  #
  # @example Setting a nested value with array path
  #   hash = {}
  #   Hash.put(hash, ['user', 'name'], 'John')
  #   # => {"user"=>{"name"=>"John"}}
  #
  # @example Setting with single key
  #   hash = {}
  #   Hash.put(hash, 'key', 'value') 
  #   # => {"key"=>"value"}
  #
  # @note Creates intermediate hashes as needed along the path
  def self.put(target, path, val)
    path = [path] unless path.is_a?(Array)
    fail ArgumentError, "path cannot be empty" if path.empty?
    root = target
    path.slice(0..-2).each { |key| target = target[key] ||= {} }
    target[path.last] = val
    root
  end

  # Converts the hash to an OpenStruct object
  #
  # @return [OpenStruct] A new OpenStruct containing the hash's key-value pairs
  #
  # @example Converting a hash to OpenStruct
  #   hash = {'name' => 'John', 'age' => 30}
  #   struct = hash.to_struct
  #   struct.name # => "John"
  #   struct.age  # => 30
  #
  # @note All keys become methods on the returned OpenStruct
  def to_struct
    OpenStruct.new self
  end
end