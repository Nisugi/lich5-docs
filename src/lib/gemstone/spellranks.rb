# Module namespace for the Lich game automation system
module Lich

  # Module namespace for Gemstone-specific functionality 
  module Gemstone

    # Manages and tracks spell ranks/training for different magical circles and abilities
    #
    # @author Lich5 Documentation Generator
    class SpellRanks
      @@list      ||= Array.new
      @@timestamp ||= 0
      @@loaded    ||= false

      # @return [String] The character name associated with these spell ranks
      attr_reader :name

      # @return [Integer] Rank in Minor Spiritual circle
      attr_accessor :minorspiritual
      # @return [Integer] Rank in Major Spiritual circle  
      attr_accessor :majorspiritual
      # @return [Integer] Rank in Cleric circle
      attr_accessor :cleric
      # @return [Integer] Rank in Minor Elemental circle
      attr_accessor :minorelemental
      # @return [Integer] Rank in Major Elemental circle
      attr_accessor :majorelemental
      # @return [Integer] Rank in Minor Mental circle
      attr_accessor :minormental
      # @return [Integer] Rank in Ranger circle
      attr_accessor :ranger
      # @return [Integer] Rank in Sorcerer circle
      attr_accessor :sorcerer
      # @return [Integer] Rank in Wizard circle
      attr_accessor :wizard
      # @return [Integer] Rank in Bard circle
      attr_accessor :bard
      # @return [Integer] Rank in Empath circle
      attr_accessor :empath
      # @return [Integer] Rank in Paladin circle
      attr_accessor :paladin
      # @return [Integer] Rank in Arcane Symbols
      attr_accessor :arcanesymbols
      # @return [Integer] Rank in Magic Item Use
      attr_accessor :magicitemuse
      # @return [Integer] Rank in Monk abilities
      attr_accessor :monk

      # Loads spell rank data from disk
      #
      # @return [void]
      # @raise [StandardError] If there are issues reading or parsing the data file
      # @note Creates an empty list if the data file doesn't exist or has errors
      def SpellRanks.load
        if File.exist?(File.join(DATA_DIR, "#{XMLData.game}", "spell-ranks.dat"))
          begin
            File.open(File.join(DATA_DIR, "#{XMLData.game}", "spell-ranks.dat"), 'rb') { |f|
              @@timestamp, @@list = Marshal.load(f.read)
            }
            # minor mental circle added 2012-07-18; old data files will have @minormental as nil
            @@list.each { |rank_info| rank_info.minormental ||= 0 }
            # monk circle added 2013-01-15; old data files will have @minormental as nil
            @@list.each { |rank_info| rank_info.monk ||= 0 }
            @@loaded = true
          rescue
            respond "--- Lich: error: SpellRanks.load: #{$!}"
            Lich.log "error: SpellRanks.load: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
            @@list      = Array.new
            @@timestamp = 0
            @@loaded = true
          end
        else
          @@loaded = true
        end
      end

      # Saves current spell rank data to disk
      #
      # @return [void]
      # @raise [StandardError] If there are issues writing to the data file
      # @example
      #   SpellRanks.save
      def SpellRanks.save
        begin
          File.open(File.join(DATA_DIR, "#{XMLData.game}", "spell-ranks.dat"), 'wb') { |f|
            f.write(Marshal.dump([@@timestamp, @@list]))
          }
        rescue
          respond "--- Lich: error: SpellRanks.save: #{$!}"
          Lich.log "error: SpellRanks.save: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
      end

      # Gets the timestamp of the last spell ranks update
      #
      # @return [Integer] Unix timestamp of last update
      # @example
      #   last_update = SpellRanks.timestamp
      def SpellRanks.timestamp
        SpellRanks.load unless @@loaded
        @@timestamp
      end

      # Sets the timestamp for spell ranks data
      #
      # @param val [Integer] Unix timestamp to set
      # @return [Integer] The new timestamp value
      # @example
      #   SpellRanks.timestamp = Time.now.to_i
      def SpellRanks.timestamp=(val)
        SpellRanks.load unless @@loaded
        @@timestamp = val
      end

      # Retrieves spell rank information for a specific character
      #
      # @param name [String] Character name to look up
      # @return [SpellRanks, nil] SpellRanks object for the character or nil if not found
      # @example
      #   ranks = SpellRanks["MyCharacter"]
      def SpellRanks.[](name)
        SpellRanks.load unless @@loaded
        @@list.find { |n| n.name == name }
      end

      # Gets the list of all spell rank records
      #
      # @return [Array<SpellRanks>] Array of all spell rank objects
      # @example
      #   all_ranks = SpellRanks.list
      def SpellRanks.list
        SpellRanks.load unless @@loaded
        @@list
      end

      # Handles undefined method calls with an error message
      #
      # @param arg [Symbol] The called method name
      # @return [void]
      # @note Outputs error message to game client
      def SpellRanks.method_missing(arg = nil)
        echo "error: unknown method #{arg} for class SpellRanks"
        respond caller[0..1]
      end

      # Creates a new spell ranks record for a character
      #
      # @param name [String] Character name to create ranks for
      # @return [SpellRanks] New SpellRanks instance
      # @example
      #   new_ranks = SpellRanks.new("MyCharacter")
      # @note Initializes all ranks to 0 and adds to internal list
      def initialize(name)
        SpellRanks.load unless @@loaded
        @name = name
        @minorspiritual, @majorspiritual, @cleric, @minorelemental, @majorelemental, @ranger, @sorcerer, @wizard, @bard, @empath, @paladin, @minormental, @arcanesymbols, @magicitemuse = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        @@list.push(self)
      end
    end
  end
end