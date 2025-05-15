# Module namespace for the Lich game automation system
module Lich
  # Module for DragonRealms specific functionality 
  module DragonRealms
    # Represents and manages the current room state in DragonRealms
    # Tracks NPCs, PCs, objects, and room properties using class variables
    #
    # @author Lich5 Documentation Generator
    class DRRoom
      @@npcs ||= []
      @@pcs ||= []
      @@group_members ||= []
      @@pcs_prone ||= []
      @@pcs_sitting ||= []
      @@dead_npcs ||= []
      @@room_objs ||= []
      @@exits ||= []
      @@title = ''
      @@description = ''

      # Gets the list of NPCs (Non-Player Characters) in the current room
      #
      # @return [Array<String>] Array of NPC names currently in the room
      # @example
      #   DRRoom.npcs #=> ["guard", "merchant", "town crier"]
      def self.npcs
        @@npcs
      end

      # Sets the list of NPCs in the current room
      #
      # @param val [Array<String>] Array of NPC names to set
      # @return [Array<String>] The new array of NPCs
      # @example
      #   DRRoom.npcs = ["guard", "merchant"]
      def self.npcs=(val)
        @@npcs = val
      end

      # Gets the list of PCs (Player Characters) in the current room
      #
      # @return [Array<String>] Array of PC names currently in the room
      # @example
      #   DRRoom.pcs #=> ["Warrior123", "Mage456"]
      def self.pcs
        @@pcs
      end

      # Sets the list of PCs in the current room
      #
      # @param val [Array<String>] Array of PC names to set
      # @return [Array<String>] The new array of PCs
      # @example
      #   DRRoom.pcs = ["Warrior123", "Mage456"]
      def self.pcs=(val)
        @@pcs = val
      end

      # Gets the available exits from the current room
      #
      # @return [Array<String>] Array of available exit directions
      # @note Delegates to XMLData.room_exits
      # @example
      #   DRRoom.exits #=> ["north", "south", "east"]
      def self.exits
        XMLData.room_exits
      end

      # Gets the title of the current room
      #
      # @return [String] The room's title
      # @note Delegates to XMLData.room_title
      # @example
      #   DRRoom.title #=> "Town Square Central"
      def self.title
        XMLData.room_title
      end

      # Gets the description of the current room
      #
      # @return [String] The room's full description
      # @note Delegates to XMLData.room_description
      # @example
      #   DRRoom.description #=> "This is the central square of the town..."
      def self.description
        XMLData.room_description
      end

      # Gets the list of group members in the current room
      #
      # @return [Array<String>] Array of group member names
      # @example
      #   DRRoom.group_members #=> ["GroupMate1", "GroupMate2"]
      def self.group_members
        @@group_members
      end

      # Sets the list of group members in the current room
      #
      # @param val [Array<String>] Array of group member names to set
      # @return [Array<String>] The new array of group members
      # @example
      #   DRRoom.group_members = ["GroupMate1", "GroupMate2"]
      def self.group_members=(val)
        @@group_members = val
      end

      # Gets the list of prone PCs in the current room
      #
      # @return [Array<String>] Array of prone PC names
      # @example
      #   DRRoom.pcs_prone #=> ["InjuredPlayer1"]
      def self.pcs_prone
        @@pcs_prone
      end

      # Sets the list of prone PCs in the current room
      #
      # @param val [Array<String>] Array of prone PC names to set
      # @return [Array<String>] The new array of prone PCs
      # @example
      #   DRRoom.pcs_prone = ["InjuredPlayer1"]
      def self.pcs_prone=(val)
        @@pcs_prone = val
      end

      # Gets the list of sitting PCs in the current room
      #
      # @return [Array<String>] Array of sitting PC names
      # @example
      #   DRRoom.pcs_sitting #=> ["RestingPlayer1"]
      def self.pcs_sitting
        @@pcs_sitting
      end

      # Sets the list of sitting PCs in the current room
      #
      # @param val [Array<String>] Array of sitting PC names to set
      # @return [Array<String>] The new array of sitting PCs
      # @example
      #   DRRoom.pcs_sitting = ["RestingPlayer1"]
      def self.pcs_sitting=(val)
        @@pcs_sitting = val
      end

      # Gets the list of dead NPCs in the current room
      #
      # @return [Array<String>] Array of dead NPC names
      # @example
      #   DRRoom.dead_npcs #=> ["dead goblin", "dead rat"]
      def self.dead_npcs
        @@dead_npcs
      end

      # Sets the list of dead NPCs in the current room
      #
      # @param val [Array<String>] Array of dead NPC names to set
      # @return [Array<String>] The new array of dead NPCs
      # @example
      #   DRRoom.dead_npcs = ["dead goblin", "dead rat"]
      def self.dead_npcs=(val)
        @@dead_npcs = val
      end

      # Gets the list of objects in the current room
      #
      # @return [Array<String>] Array of object names in the room
      # @example
      #   DRRoom.room_objs #=> ["chest", "barrel", "sign"]
      def self.room_objs
        @@room_objs
      end

      # Sets the list of objects in the current room
      #
      # @param val [Array<String>] Array of object names to set
      # @return [Array<String>] The new array of room objects
      # @example
      #   DRRoom.room_objs = ["chest", "barrel", "sign"]
      def self.room_objs=(val)
        @@room_objs = val
      end
    end
  end
end