# Carve out class SpellRanks
# 2024-06-13

module Lich
  module Gemstone
    # Represents the ranks of spells available in the game.
    # 
    # This class handles loading and saving spell rank data, as well as providing access to
    # individual spell ranks and their properties.
    class SpellRanks
      @@list      ||= Array.new
      @@timestamp ||= 0
      @@loaded    ||= false
      attr_reader :name
      attr_accessor :minorspiritual, :majorspiritual, :cleric, :minorelemental, :majorelemental, :minormental, :ranger, :sorcerer, :wizard, :bard, :empath, :paladin, :arcanesymbols, :magicitemuse, :monk

      # Loads the spell ranks from a data file.
      #
      # @return [void]
      # @raise [StandardError] if there is an error reading the file.
      # @example
      #   SpellRanks.load
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

      # Saves the current spell ranks to a data file.
      #
      # @return [void]
      # @raise [StandardError] if there is an error writing to the file.
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

      # Retrieves the timestamp of the last load operation.
      #
      # @return [Integer] the timestamp of the last load operation.
      # @note This method will load the spell ranks if they have not been loaded yet.
      # @example
      #   timestamp = SpellRanks.timestamp
      def SpellRanks.timestamp
        SpellRanks.load unless @@loaded
        @@timestamp
      end

      # Sets the timestamp for the last load operation.
      #
      # @param [Integer] val the new timestamp value.
      # @return [void]
      # @note This method will load the spell ranks if they have not been loaded yet.
      # @example
      #   SpellRanks.timestamp = Time.now.to_i
      def SpellRanks.timestamp=(val)
        SpellRanks.load unless @@loaded
        @@timestamp = val
      end

      # Finds a spell rank by its name.
      #
      # @param [String] name the name of the spell rank to find.
      # @return [SpellRanks, nil] the spell rank object if found, otherwise nil.
      # @note This method will load the spell ranks if they have not been loaded yet.
      # @example
      #   rank = SpellRanks["Fireball"]
      def SpellRanks.[](name)
        SpellRanks.load unless @@loaded
        @@list.find { |n| n.name == name }
      end

      # Retrieves the list of all spell ranks.
      #
      # @return [Array<SpellRanks>] the list of all spell ranks.
      # @note This method will load the spell ranks if they have not been loaded yet.
      # @example
      #   ranks = SpellRanks.list
      def SpellRanks.list
        SpellRanks.load unless @@loaded
        @@list
      end

      # Handles calls to undefined methods for the SpellRanks class.
      #
      # @param [Symbol, String] arg the name of the method that was called.
      # @return [void]
      # @example
      #   SpellRanks.some_undefined_method
      def SpellRanks.method_missing(arg = nil)
        echo "error: unknown method #{arg} for class SpellRanks"
        respond caller[0..1]
      end

      # Initializes a new instance of the SpellRanks class.
      #
      # @param [String] name the name of the spell rank.
      # @return [void]
      # @note This method will load the spell ranks if they have not been loaded yet.
      # @example
      #   spell_rank = SpellRanks.new("Fireball")
      def initialize(name)
        SpellRanks.load unless @@loaded
        @name = name
        @minorspiritual, @majorspiritual, @cleric, @minorelemental, @majorelemental, @ranger, @sorcerer, @wizard, @bard, @empath, @paladin, @minormental, @arcanesymbols, @magicitemuse = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        @@list.push(self)
      end
    end
  end
end