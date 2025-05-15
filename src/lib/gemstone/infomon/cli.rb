# frozen_string_literal: true

# Provides command-line interface functionality for the Infomon system in Lich Gemstone
# Handles character information synchronization and database management
#
# @author Lich5 Documentation Generator
module Lich
  module Gemstone
    module Infomon
      # CLI commands for Infomon

      # Synchronizes character information by executing a series of game commands
      # and capturing their responses. Temporarily disables Shroud of Deception if active.
      #
      # @return [void]
      # @note This method will automatically disable Shroud of Deception (spell 1212) if active,
      #   and notify the user to reactivate it after completion
      # @example
      #   Lich::Gemstone::Infomon.sync
      #
      # @note Commands executed include: info, skill, spell, experience, society, citizenship,
      #   armor list all, cman list all, feat list all, shield list all, weapon list all,
      #   ascension list all, resource, and warcry
      def self.sync
        # since none of this information is 3rd party displayed, silence is golden.
        shroud_detected = false
        respond 'Infomon sync requested.'
        if Effects::Spells.active?(1212)
          respond 'ATTENTION:  SHROUD DETECTED - disabling Shroud of Deception to sync character\'s infomon setting'
          while Effects::Spells.active?(1212)
            dothistimeout('STOP 1212', 3, /^With a moment's concentration, you terminate the Shroud of Deception spell\.$|^Stop what\?$/)
            sleep(0.5)
          end
          shroud_detected = true
        end
        request = { 'info'               => /<a exist=.+#{XMLData.name}/,
                    'skill'              => /<a exist=.+#{XMLData.name}/,
                    'spell'              => %r{<output class="mono"/>},
                    'experience'         => %r{<output class="mono"/>},
                    'society'            => %r{<pushBold/>},
                    'citizenship'        => /^You don't seem|^You currently have .+ in/,
                    'armor list all'     => /<a exist=.+#{XMLData.name}/,
                    'cman list all'      => /<a exist=.+#{XMLData.name}/,
                    'feat list all'      => /<a exist=.+#{XMLData.name}/,
                    'shield list all'    => /<a exist=.+#{XMLData.name}/,
                    'weapon list all'    => /<a exist=.+#{XMLData.name}/,
                    'ascension list all' => /<a exist=.+#{XMLData.name}/,
                    'resource'           => /^Health: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Mana: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Stamina: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Spirit: \d+\/(?:<pushBold\/>)?\d+/,
                    'warcry'             => /^You have learned the following War Cries:|^You must be an active member of the Warrior Guild to use this skill/ }

        request.each do |command, start_capture|
          respond "Retrieving character #{command}." if $infomon_debug
          Lich::Util.issue_command(command.to_s, start_capture, /<prompt/, include_end: true, timeout: 5, silent: false, usexml: true, quiet: true)
          respond "Did #{command}." if $infomon_debug
        end
        respond 'Requested Infomon sync complete.'
        respond 'ATTENTION:  TEND TO YOUR SHROUD!' if shroud_detected
        Infomon.set('infomon.last_sync', Time.now.to_i)
      end

      # Performs a complete reset of the Infomon database and repopulates it with fresh data
      #
      # @return [void]
      # @note This is a destructive operation that will delete all existing character data
      # @example
      #   Lich::Gemstone::Infomon.redo!
      def self.redo!
        # Destructive - deletes char table, recreates it, then repopulates it
        respond 'Infomon complete reset reqeusted.'
        Infomon.reset!
        Infomon.sync
        respond 'Infomon reset is now complete.'
      end

      # Displays stored information for the current character
      #
      # @param full [Boolean] When true, shows all values including zeros. When false,
      #   filters out entries with zero values
      # @return [void]
      # @example Show non-zero values only
      #   Lich::Gemstone::Infomon.show
      # @example Show all values including zeros
      #   Lich::Gemstone::Infomon.show(true)
      def self.show(full = false)
        response = []
        # display all stored db values
        respond "Displaying stored information for #{XMLData.name}"
        Infomon.table.map([:key, :value]).each { |k, v|
          response << "#{k} : #{v.inspect}\n"
        }
        unless full
          response.each { |_line|
            response.reject! do |line|
              line.match?(/\s:\s0$/)
            end
          }
        end
        respond response
      end

      # Determines if the database needs to be refreshed based on last sync time
      #
      # @return [Boolean] Returns true if the database needs refreshing, false otherwise
      # @note The refresh check is based on a hardcoded date (August 5, 2024) which represents
      #   the last database structure change
      # @example
      #   if Lich::Gemstone::Infomon.db_refresh_needed?
      #     # perform refresh operations
      #   end
      def self.db_refresh_needed?
        # Change date below to the last date of infomon.db structure change to allow for a forced reset of data.
        Infomon.get("infomon.last_sync").nil? || Infomon.get("infomon.last_sync") < Time.new(2024, 8, 5, 20, 0, 0).to_i
      end
    end
  end
end