# carveout for infomon rewrite
module Lich
  module Gemstone
    # Represents the Society within the Gemstone module.
    class Society
      # Retrieves the current status of the society.
      #
      # @return [String] the current status of the society.
      # @raise [StandardError] if there is an issue retrieving the status.
      # @example
      #   status = Lich::Gemstone::Society.status
      def self.status
        Infomon.get("society.status")
      end

      # Retrieves the current rank of the society.
      #
      # @return [String] the current rank of the society.
      # @raise [StandardError] if there is an issue retrieving the rank.
      # @example
      #   rank = Lich::Gemstone::Society.rank
      def self.rank
        Infomon.get("society.rank")
      end

      # Retrieves the current step of the society, which is equivalent to its rank.
      #
      # @return [String] the current step of the society.
      # @note This method is an alias for the rank method.
      # @example
      #   step = Lich::Gemstone::Society.step
      def self.step
        self.rank
      end

      # Duplicates the current status of the society.
      #
      # @return [String] a duplicate of the current status of the society.
      # @note The returned status is a copy, modifications to it will not affect the original.
      # @example
      #   member_status = Lich::Gemstone::Society.member
      def self.member
        self.status.dup
      end

      # Retrieves the current task of the society from XML data.
      #
      # @return [String] the current task of the society.
      # @raise [StandardError] if there is an issue retrieving the task.
      # @example
      #   task = Lich::Gemstone::Society.task
      def self.task
        XMLData.society_task
      end

      # Retrieves the current favor of the society.
      #
      # @return [Integer] the current favor of the society.
      # @raise [StandardError] if there is an issue retrieving the favor.
      # @example
      #   favor = Lich::Gemstone::Society.favor
      def self.favor
        Infomon.get('resources.voln_favor')
      end

      # Serializes the current status and rank of the society into an array.
      #
      # @return [Array<String>] an array containing the current status and rank of the society.
      # @example
      #   serialized_data = Lich::Gemstone::Society.serialize
      def self.serialize
        [self.status, self.rank]
      end
    end
  end
end
