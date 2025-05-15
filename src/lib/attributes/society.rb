# Provides functionality for interacting with society-related game information in Gemstone
# 
# @author Lich5 Documentation Generator
module Lich

  # Contains Gemstone-specific functionality and data structures
  module Gemstone

    # Manages and provides access to character society information
    #
    # This class provides methods to check society status, rank, tasks and other
    # society-related information for a character in Gemstone.
    class Society
      # Gets the current society status/membership of the character
      #
      # @return [String] The name of the society the character belongs to
      # @example
      #   Society.status #=> "Voln"
      def self.status
        Infomon.get("society.status")
      end

      # Gets the character's current rank/step in their society
      #
      # @return [Integer] The numeric rank in the society
      # @example
      #   Society.rank #=> 26
      def self.rank
        Infomon.get("society.rank")
      end

      # Alias for rank - gets the character's current society step
      #
      # @return [Integer] The numeric rank/step in the society
      # @see #rank
      # @example
      #   Society.step #=> 26
      def self.step
        self.rank
      end

      # Gets a copy of the character's society membership status
      #
      # @return [String] A duplicate of the society status string
      # @example
      #   Society.member #=> "Voln"
      def self.member
        self.status.dup
      end

      # Gets the character's current society task
      #
      # @return [String, nil] The current task description or nil if no active task
      # @example
      #   Society.task #=> "Help the wounded in the Temple"
      def self.task
        XMLData.society_task
      end

      # Gets the character's current favor points in the Society of Voln
      #
      # @return [Integer] The amount of favor points
      # @example
      #   Society.favor #=> 100
      def self.favor
        Infomon.get('resources.voln_favor')
      end

      # Creates an array containing the character's society status and rank
      #
      # @return [Array<String,Integer>] Array containing [status, rank]
      # @example
      #   Society.serialize #=> ["Voln", 26]
      def self.serialize
        [self.status, self.rank]
      end
    end
  end
end