module Lich
  module Gemstone
    # Represents a disk item in the game.
    class Disk
      NOUNS = %w{cassone chest coffer coffin coffret disk hamper saucer sphere trunk tureen}

      # Checks if the given object is a disk based on its name.
      #
      # @param thing [Object] The object to check.
      # @return [Boolean] Returns true if the object is a disk, false otherwise.
      # @example
      #   Disk.is_disk?(some_object)
      def self.is_disk?(thing)
        thing.name =~ /\b([A-Z][a-z]+) #{Regexp.union(NOUNS)}\b/
      end

      # Finds a disk by its name.
      #
      # @param name [String] The name of the disk to find.
      # @return [Disk, nil] Returns a Disk object if found, nil otherwise.
      # @example
      #   Disk.find_by_name("golden disk")
      def self.find_by_name(name)
        disk = GameObj.loot.find do |item|
          is_disk?(item) && item.name.include?(name)
        end
        return nil if disk.nil?
        Disk.new(disk)
      end

      # Mines a disk based on the character's name.
      #
      # @return [Disk, nil] Returns a Disk object if found, nil otherwise.
      # @example
      #   Disk.mine
      def self.mine
        find_by_name(Char.name)
      end

      # Retrieves all disk objects from the loot.
      #
      # @return [Array<Disk>] An array of Disk objects.
      # @example
      #   Disk.all
      def self.all()
        (GameObj.loot || []).select do |item|
          is_disk?(item)
        end.map do |i|
          Disk.new(i)
        end
      end

      attr_reader :id, :name

      # Initializes a new Disk object.
      #
      # @param obj [Object] The object representing the disk.
      # @return [Disk] A new Disk instance.
      # @example
      #   disk = Disk.new(some_game_object)
      def initialize(obj)
        @id   = obj.id
        @name = obj.name.split(" ").find do |word|
          word[0].upcase.eql?(word[0])
        end
      end

      # Compares this Disk object with another for equality.
      #
      # @param other [Object] The object to compare with.
      # @return [Boolean] Returns true if the objects are equal, false otherwise.
      # @example
      #   disk1 == disk2
      def ==(other)
        other.is_a?(Disk) && other.id == self.id
      end

      # Checks if this Disk object is equal to another.
      #
      # @param other [Object] The object to compare with.
      # @return [Boolean] Returns true if the objects are equal, false otherwise.
      # @example
      #   disk1.eql?(disk2)
      def eql?(other)
        self == other
      end

      # Handles missing methods by delegating to the GameObj.
      #
      # @param method [Symbol] The method name that was called.
      # @param args [Array] The arguments passed to the method.
      # @return [Object] The result of the method call on GameObj.
      # @example
      #   disk.some_missing_method
      def method_missing(method, *args)
        GameObj[@id].send(method, *args)
      end

      # Converts the Disk object to a container.
      #
      # @return [Container, Object] Returns a Container object if defined, otherwise the GameObj.
      # @note This method depends on the existence of the Container class.
      # @example
      #   disk.to_container
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