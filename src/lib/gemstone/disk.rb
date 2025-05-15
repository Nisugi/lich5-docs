# A module namespace for the Lich game automation system
module Lich
  # Module containing Gemstone-specific functionality 
  module Gemstone
    # Represents a disk container object in the game that can store items
    # Used to manage and interact with personal storage disks
    #
    # @author Lich5 Documentation Generator
    class Disk
      # List of valid nouns that identify disk containers in the game
      # @return [Array<String>] Array of valid disk container noun identifiers
      NOUNS = %w{cassone chest coffer coffin coffret disk hamper saucer sphere trunk tureen}

      # Determines if a given game object is a valid disk container
      #
      # @param thing [GameObj] The game object to check
      # @return [Boolean] true if the object is a valid disk container, false otherwise
      # @example
      #   Disk.is_disk?(some_game_obj) #=> true/false
      #
      # @note Checks if the object name matches pattern "[Name] [valid_noun]"
      def self.is_disk?(thing)
        thing.name =~ /\b([A-Z][a-z]+) #{Regexp.union(NOUNS)}\b/
      end

      # Finds a disk container by a specific name
      #
      # @param name [String] The name to search for in disk containers
      # @return [Disk, nil] Returns a new Disk instance if found, nil if not found
      # @example
      #   disk = Disk.find_by_name("Bob") #=> #<Disk:0x...> or nil
      def self.find_by_name(name)
        disk = GameObj.loot.find do |item|
          is_disk?(item) && item.name.include?(name)
        end
        return nil if disk.nil?
        Disk.new(disk)
      end

      # Finds the disk container belonging to the current character
      #
      # @return [Disk, nil] Returns the character's disk if found, nil otherwise
      # @example
      #   my_disk = Disk.mine #=> #<Disk:0x...>
      def self.mine
        find_by_name(Char.name)
      end

      # Returns all disk containers currently visible
      #
      # @return [Array<Disk>] Array of all visible disk containers
      # @example
      #   all_disks = Disk.all #=> [#<Disk:0x...>, #<Disk:0x...>]
      def self.all()
        (GameObj.loot || []).select do |item|
          is_disk?(item)
        end.map do |i|
          Disk.new(i)
        end
      end

      # @return [String] The unique identifier of the disk
      attr_reader :id
      # @return [String] The name of the disk owner
      attr_reader :name

      # Creates a new Disk instance
      #
      # @param obj [GameObj] The game object representing the disk
      # @return [Disk] A new disk instance
      # @example
      #   disk = Disk.new(game_obj)
      #
      # @note Extracts the owner's name from the disk's full name
      def initialize(obj)
        @id   = obj.id
        @name = obj.name.split(" ").find do |word|
          word[0].upcase.eql?(word[0])
        end
      end

      # Compares this disk with another for equality
      #
      # @param other [Object] The object to compare with
      # @return [Boolean] true if the objects are the same disk, false otherwise
      # @example
      #   disk1 == disk2 #=> true/false
      def ==(other)
        other.is_a?(Disk) && other.id == self.id
      end

      # Hash equality comparison
      #
      # @param other [Object] The object to compare with
      # @return [Boolean] true if the objects are the same disk, false otherwise
      # @example
      #   disk1.eql?(disk2) #=> true/false
      def eql?(other)
        self == other
      end

      # Forwards unknown method calls to the underlying game object
      #
      # @param method [Symbol] The method name to call
      # @param args [Array] Arguments to pass to the method
      # @return [Object] Result of the forwarded method call
      # @example
      #   disk.some_game_obj_method
      def method_missing(method, *args)
        GameObj[@id].send(method, *args)
      end

      # Converts the disk to a Container object if available
      #
      # @return [Container, GameObj] Returns a Container instance if the Container class exists,
      #   otherwise returns the raw GameObj
      # @example
      #   disk.to_container #=> #<Container:0x...> or GameObj
      #
      # @note Provides compatibility with the Container system when available
      def to_container
        if defined?(Container)
          Container.new(@id)
        else
          GameObj["#{@id}"]
        end
      end
    end
  end
end