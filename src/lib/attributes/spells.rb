require "ostruct"

# Namespace module for the Lich application
module Lich
  # Module containing Gemstone-specific functionality
  module Gemstone
    # Handles spell-related functionality and spell circle management in Gemstone
    #
    # @author Lich5 Documentation Generator
    module Spells
      # Converts a numeric circle identifier to its corresponding circle name
      #
      # @param num [String, Integer] The circle number to convert
      # @return [String] The human-readable name of the spell circle
      # @example
      #   Lich::Gemstone::Spells.get_circle_name(1) #=> "Minor Spirit"
      #   Lich::Gemstone::Spells.get_circle_name("4") #=> "Minor Elemental"
      def self.get_circle_name(num)
        case num.to_s
        when '1' then 'Minor Spirit'
        when '2' then 'Major Spirit'
        when '3' then 'Cleric'
        when '4' then 'Minor Elemental'
        when '5' then 'Major Elemental'
        when '6' then 'Ranger'
        when '7' then 'Sorcerer'
        when '8' then 'Old Healing List'
        when '9' then 'Wizard'
        when '10' then 'Bard'
        when '11' then 'Empath'
        when '12' then 'Minor Mental'
        when '16' then 'Paladin'
        when '17' then 'Arcane'
        when '65' then 'Imbedded Enchantment'
        when '66' then 'Death'
        when '90' then 'Micellaneous'
        when '95' then 'Armor Specialization'
        when '96' then 'Combat Maneuvers'
        when '97' then 'Guardians of Sunfist'
        when '98' then 'Order of Voln'
        when '99' then 'Council of Light'
        else 'Unknown Circle'
        end
      end

      # Returns all currently active spells
      #
      # @return [Array<Spell>] List of currently active spells
      # @example
      #   Lich::Gemstone::Spells.active #=> [#<Spell:101>, #<Spell:203>]
      def self.active
        Spell.active
      end

      # Returns all spells known by the character
      #
      # @return [Array<Spell>] List of known spells
      # @example
      #   Lich::Gemstone::Spells.known #=> [#<Spell:101>, #<Spell:102>]
      def self.known
        known_spells = Array.new
        Spell.list.each { |spell| known_spells.push(spell) if spell.known? }
        return known_spells
      end

      # Handles cooldown requirements for specific spells
      #
      # @param spell [Spell] The spell to check for cooldown requirements
      # @return [:ok, nil] Returns :ok if no cooldown needed, nil if cooldown was applied
      # @note Specifically handles Ranger Aspects (9014-9041) and Rapid Fire (515)
      # @example
      #   Lich::Gemstone::Spells.require_cooldown(ranger_aspect_spell)
      def self.require_cooldown(spell)
        if (spell.num.to_i > 9013) && (spell.num.to_i < 9042) # Assume Aspect: Ranger
          cooldown_spell = Spell[spell.num + 1]
          cooldown_spell.putup
        elsif (spell.num == 515) && (recovery = Spell[599]) # Rapid Fire: Major Elemental
          recovery.putup
        else
          :ok
        end
      end

      # Serializes all spell circle ranks into an array
      #
      # @return [Array<Integer>] Array of spell ranks in standard order
      # @example
      #   Lich::Gemstone::Spells.serialize #=> [50, 45, 30, 40, 35, 20, 25, 15, 10, 5, 0, 0]
      def self.serialize
        [self.minor_elemental, self.major_elemental, self.minor_spiritual, self.major_spiritual, self.wizard, self.sorcerer, self.ranger, self.paladin, self.empath, self.cleric, self.bard, self.minormental]
      end

      # @private
      # List of valid spell circles
      # @return [Array<Symbol>]
      @@spell_lists = %i(major_elemental major_spiritual minor_elemental minor_mental minor_spiritual bard cleric empath paladin ranger sorcerer wizard)

      # returns rank as integer
      @@spell_lists.each do |spell_list|
        # @!method major_elemental
        # @return [Integer] Returns the rank in Major Elemental spells
        #
        # @!method major_spiritual  
        # @return [Integer] Returns the rank in Major Spiritual spells
        #
        # @!method minor_elemental
        # @return [Integer] Returns the rank in Minor Elemental spells
        #
        # @!method minor_mental
        # @return [Integer] Returns the rank in Minor Mental spells
        #
        # @!method minor_spiritual
        # @return [Integer] Returns the rank in Minor Spiritual spells
        #
        # @!method bard
        # @return [Integer] Returns the rank in Bard spells
        #
        # @!method cleric
        # @return [Integer] Returns the rank in Cleric spells
        #
        # @!method empath
        # @return [Integer] Returns the rank in Empath spells
        #
        # @!method paladin
        # @return [Integer] Returns the rank in Paladin spells
        #
        # @!method ranger
        # @return [Integer] Returns the rank in Ranger spells
        #
        # @!method sorcerer
        # @return [Integer] Returns the rank in Sorcerer spells
        #
        # @!method wizard
        # @return [Integer] Returns the rank in Wizard spells
        self.define_singleton_method(spell_list) do
          Infomon.get("spell.%s" % spell_list).to_i
        end
      end

      # these are here for backwards compat
      %i(majorelemental majorspiritual minorelemental minormental minorspiritual).each do |shorthand|
        # @!method majorelemental
        # @return [Integer] Alias for major_elemental
        # @deprecated Use major_elemental instead
        #
        # @!method majorspiritual
        # @return [Integer] Alias for major_spiritual
        # @deprecated Use major_spiritual instead
        #
        # @!method minorelemental
        # @return [Integer] Alias for minor_elemental
        # @deprecated Use minor_elemental instead
        #
        # @!method minormental
        # @return [Integer] Alias for minor_mental
        # @deprecated Use minor_mental instead
        #
        # @!method minorspiritual
        # @return [Integer] Alias for minor_spiritual
        # @deprecated Use minor_spiritual instead
        long_hand = @@spell_lists.find { |method| method.to_s.gsub(/_/, '').eql?(shorthand.to_s) }
        self.define_singleton_method(shorthand) do
          Spells.send(long_hand)
        end
      end
    end
  end
end