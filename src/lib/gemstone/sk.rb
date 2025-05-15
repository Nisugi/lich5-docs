# Module for handling Savvy Knife (SK) spell management in Gemstone
# Provides functionality to track known SK spells and manage spell lists
#
# @author Lich5 Documentation Generator
module Lich
  module Gemstone
    module SK
      @sk_known = nil

      # Gets the list of known SK spells for the current character
      #
      # @return [Array<String>] Array of known spell numbers as strings
      # @note Loads from database storage, falling back to legacy storage if needed
      #
      # @example
      #   SK.sk_known #=> ["101", "102", "103"]
      def self.sk_known
        if @sk_known.nil?
          val = DB_Store.read("#{XMLData.game}:#{XMLData.name}", "sk_known")
          if val.nil? || (val.class == Hash && val.empty?)
            old_settings = DB_Store.read("#{XMLData.game}:#{XMLData.name}", "vars")["sk/known"]
            if old_settings.class == Array
              val = old_settings
            else
              val = []
            end
            self.sk_known = val
          end
          @sk_known = val unless val.nil?
        end
        return @sk_known
      end

      # Sets the list of known SK spells for the current character
      #
      # @param val [Array<String>] Array of spell numbers to save
      # @return [Array<String>] The updated spell list
      # @note Persists changes to database storage
      #
      # @example
      #   SK.sk_known = ["101", "102"]
      def self.sk_known=(val)
        return @sk_known if @sk_known == val
        DB_Store.save("#{XMLData.game}:#{XMLData.name}", "sk_known", val)
        @sk_known = val
      end

      # Checks if a specific spell is known
      #
      # @param spell [Object] Spell object with a num attribute
      # @return [Boolean] true if spell is known, false otherwise
      #
      # @example
      #   SK.known?(some_spell) #=> true
      def self.known?(spell)
        self.sk_known if @sk_known.nil?
        @sk_known.include?(spell.num.to_s)
      end

      # Displays the current list of known SK spells
      #
      # @return [nil] Outputs spell list to game window
      #
      # @example
      #   SK.list
      def self.list
        respond "Current SK Spells: #{@sk_known.inspect}"
        respond ""
      end

      # Displays help information about SK commands
      #
      # @return [nil] Outputs help text to game window
      #
      # @example
      #   SK.help
      def self.help
        respond "   Script to add SK spells to be known and used with Spell API calls."
        respond ""
        respond "   ;sk add <SPELL_NUMBER>  - Add spell number to saved list"
        respond "   ;sk rm <SPELL_NUMBER>   - Remove spell number from saved list"
        respond "   ;sk list                - Show all currently saved SK spell numbers"
        respond "   ;sk help                - Show this menu"
        respond ""
      end

      # Adds one or more spell numbers to the known spells list
      #
      # @param numbers [Array<String>] Spell numbers to add
      # @return [Array<String>] Updated list of known spells
      # @note Automatically deduplicates the list
      #
      # @example
      #   SK.add("101", "102")
      def self.add(*numbers)
        self.sk_known = (@sk_known + numbers).uniq
        self.list
      end

      # Removes one or more spell numbers from the known spells list
      #
      # @param numbers [Array<String>] Spell numbers to remove
      # @return [Array<String>] Updated list of known spells
      # @note Automatically deduplicates the list
      #
      # @example
      #   SK.remove("101", "102")
      def self.remove(*numbers)
        self.sk_known = (@sk_known - numbers).uniq
        self.list
      end

      # Main command processor for SK functionality
      #
      # @param action [Symbol] Command to execute (:add, :rm, :list, :help)
      # @param spells [String, nil] Space-separated spell numbers
      # @return [nil] Executes requested command and displays output
      # @note Default action is help if no valid command given
      #
      # @example
      #   SK.main(:add, "101 102")
      #   SK.main(:list)
      #   SK.main(:rm, "101")
      def self.main(action = help, spells = nil)
        self.sk_known if @sk_known.nil?
        action = action.to_sym
        spells = spells.split(" ").uniq
        case action
        when :add
          self.add(*spells) unless spells.empty?
          self.help if spells.empty?
        when :rm
          self.remove(*spells) unless spells.empty?
          self.help if spells.empty?
        when :list
          self.list
        else
          self.help
        end
      end
    end
  end
end