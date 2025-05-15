module Lich
  module Gemstone
    module SK
      @sk_known = nil

      # Retrieves the list of known SK spells.
      #
      # @return [Array<String>] the list of known SK spell numbers as strings.
      # @note If the known spells are not set, it attempts to read from the database.
      # @example
      #   known_spells = Lich::Gemstone::SK.sk_known
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

      # Sets the list of known SK spells.
      #
      # @param val [Array<String>] the new list of known SK spell numbers.
      # @return [Array<String>] the updated list of known SK spell numbers.
      # @note This method saves the new list to the database.
      # @example
      #   Lich::Gemstone::SK.sk_known = ["1", "2", "3"]
      def self.sk_known=(val)
        return @sk_known if @sk_known == val
        DB_Store.save("#{XMLData.game}:#{XMLData.name}", "sk_known", val)
        @sk_known = val
      end

      # Checks if a specific spell is known.
      #
      # @param spell [Object] the spell object to check.
      # @return [Boolean] true if the spell is known, false otherwise.
      # @raise [NoMethodError] if spell does not respond to `num`.
      # @example
      #   is_known = Lich::Gemstone::SK.known?(some_spell)
      def self.known?(spell)
        self.sk_known if @sk_known.nil?
        @sk_known.include?(spell.num.to_s)
      end

      # Lists the current known SK spells.
      #
      # @return [void]
      # @example
      #   Lich::Gemstone::SK.list
      def self.list
        respond "Current SK Spells: #{@sk_known.inspect}"
        respond ""
      end

      # Provides help information for SK spell commands.
      #
      # @return [void]
      # @example
      #   Lich::Gemstone::SK.help
      def self.help
        respond "   Script to add SK spells to be known and used with Spell API calls."
        respond ""
        respond "   ;sk add <SPELL_NUMBER>  - Add spell number to saved list"
        respond "   ;sk rm <SPELL_NUMBER>   - Remove spell number from saved list"
        respond "   ;sk list                - Show all currently saved SK spell numbers"
        respond "   ;sk help                - Show this menu"
        respond ""
      end

      # Adds one or more spell numbers to the list of known SK spells.
      #
      # @param numbers [Array<String>] the spell numbers to add.
      # @return [void]
      # @example
      #   Lich::Gemstone::SK.add("1", "2")
      def self.add(*numbers)
        self.sk_known = (@sk_known + numbers).uniq
        self.list
      end

      # Removes one or more spell numbers from the list of known SK spells.
      #
      # @param numbers [Array<String>] the spell numbers to remove.
      # @return [void]
      # @example
      #   Lich::Gemstone::SK.remove("1")
      def self.remove(*numbers)
        self.sk_known = (@sk_known - numbers).uniq
        self.list
      end

      # Main entry point for SK spell commands.
      #
      # @param action [Symbol] the action to perform (add, rm, list, help).
      # @param spells [String, nil] the spell numbers to process (if applicable).
      # @return [void]
      # @example
      #   Lich::Gemstone::SK.main(:add, "1 2")
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