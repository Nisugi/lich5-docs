# Module for handling and tracking active spells and their durations in the Gemstone game
# Provides functionality to monitor, update and display spell durations
#
# @author Lich5 Documentation Generator
module Lich
  module Gemstone
    module ActiveSpell
      #
      # Spell timing true-up (Invoker and SK item spells do not have proper durations)
      # this needs to be addressed in class Spell rewrite
      # in the meantime, this should mean no spell is more than 1 second off from
      # Simu's time calculations
      #

      # @!attribute [r] current_durations
      #   @return [Hash] Hash storing current spell durations
      @current_durations ||= Hash.new

      # @!attribute [r] durations_first_pass_complete  
      #   @return [Boolean] Flag indicating if first pass of duration checking is complete
      @durations_first_pass_complete ||= false

      # Checks if spell durations should be shown to the user
      #
      # @return [Boolean] true if durations should be shown, false otherwise
      # @example
      #   ActiveSpell.show_durations? #=> true
      def self.show_durations?
        Infomon.get_bool("infomon.show_durations")
      end

      # Processes and normalizes spell information from the game
      #
      # @param spell_check [Hash] Hash of active spells and their data (defaults to XMLData.active_spells)
      # @return [Array<Array, Hash>] Returns two-element array containing:
      #   - Array of normalized spell names
      #   - Hash of spell names mapped to their duration data
      # @example
      #   names, durations = ActiveSpell.get_spell_info
      # @note Handles special cases like "Mage Armor", "Cloak of Shadows" etc.
      def self.get_spell_info(spell_check = XMLData.active_spells)
        respond "spell update requested\r\n" if $infomon_debug
        spell_update_durations = spell_check
        spell_update_names = []
        makeychange = []
        spell_update_durations.each do |k, _v|
          case k
          when /(?:Mage Armor|520) - /
            makeychange << k
            spell_update_names.push('Mage Armor')
            next
          when /(?:CoS|712) - /
            makeychange << k
            spell_update_names.push('Cloak of Shadows')
            next
          when /Enh\./
            makeychange << k
            case k
            when /Enh\. Strength/
              spell_update_names.push('Surge of Strength')
            when /Enh\. (?:Dexterity|Agility)/
              spell_update_names.push('Burst of Swiftness')
            end
            next
          when /Empowered/
            makeychange << k
            spell_update_names.push('Shout')
            next
          when /Multi-Strike/
            makeychange << k
            spell_update_names.push('MStrike Cooldown')
            next
          when /Next Bounty Cooldown/
            makeychange << k
            spell_update_names.push('Next Bounty')
            next
          when /(?:Resist Nature|620) (?:- (?:Heat|Cold) \(\d\d%|- Steam \(\d\d|- Lightning|\(\d\d%\))/
            makeychange << k
            spell_update_names.push('Resist Nature')
            next
          end
          spell_update_names << k
        end
        makeychange.each do |changekey|
          next unless spell_update_durations.key?(changekey)

          case changekey
          when /(?:Mage Armor|520) - /
            spell_update_durations['Mage Armor'] = spell_update_durations.delete changekey
          when /(?:CoS|712) - /
            spell_update_durations['Cloak of Shadows'] = spell_update_durations.delete changekey
          when /Enh\. Strength/
            spell_update_durations['Surge of Strength'] = spell_update_durations.delete changekey
          when /Enh\. (?:Dexterity|Agility)/
            spell_update_durations['Burst of Swiftness'] = spell_update_durations.delete changekey
          when /Empowered/
            spell_update_durations['Shout'] = spell_update_durations.delete changekey
          when /Multi-Strike/
            spell_update_durations['MStrike Cooldown'] = spell_update_durations.delete changekey
          when /Next Bounty Cooldown/
            spell_update_durations['Next Bounty'] = spell_update_durations.delete changekey
          when /Next Group Bounty Cooldown/
            spell_update_durations['Next Group Bounty'] = spell_update_durations.delete changekey
          when /(?:Resist Nature|620) (?:- (?:Heat|Cold) \(\d\d%|- Steam \(\d\d|- Lightning|\(\d\d%\))/
            spell_update_durations['Resist Nature'] = spell_update_durations.delete changekey
          end
        end
        [spell_update_names, spell_update_durations]
      end

      # Displays changes in spell durations to the user
      #
      # @return [void]
      # @note Only shows duration changes after first pass is complete
      # @example
      #   ActiveSpell.show_duration_change
      def self.show_duration_change
        active_durations = Array.new
        group_effects = [307, 310, 1605, 1609, 1618, 1608]
        [Effects::Spells.dup, Effects::Cooldowns.dup, Effects::Buffs.dup, Effects::Debuffs.dup].each do |effect_type|
          active_durations += effect_type.to_h.keys
          effect_type.to_h.each do |effect, end_time|
            next unless effect.is_a?(String)
            effect, end_time = ActiveSpell.get_spell_info({ effect=>end_time })
            effect = effect.join
            end_time = end_time[effect]
            next unless (spell = Spell.list.find { |s| s.num == effect.to_i || s.name =~ /^#{effect}$/ })
            if effect_type.to_h.find { |k, _v| k == spell.num }
              effect_key = spell.num
            else
              effect_key = spell.name
            end
            time_left = ((end_time - Time.now) / 60).to_f
            duration = ((end_time - (@current_durations[effect_key].nil? ? Time.now : @current_durations[effect_key])) / 60).to_f
            if @durations_first_pass_complete && (@current_durations[effect_key].nil? || end_time > @current_durations[effect_key]) && duration > (0.1).to_f && !(group_effects.include?(spell.num) && !spell.known?)
              respond "[ #{spell.num} #{spell.name}: +#{duration.as_time}, #{time_left.as_time} ]"
            end
            @current_durations[effect_key] = end_time
          end
        end
        (@current_durations.keys - active_durations).each do |spell|
          respond "[ #{Spell.list.find { |s| s.num == spell.to_i || s.name =~ /#{spell}/ }.num} #{Spell.list.find { |s| s.num == spell.to_i || s.name =~ /#{spell}/ }.name}: Ended ]" if @durations_first_pass_complete
          @current_durations.delete(spell)
        end
        @durations_first_pass_complete = true
      end

      # Updates the duration information for all active spells
      #
      # @return [void]
      # @raise [StandardError] If there's an error processing spell durations
      # @note Ignores certain spells like "Berserk", "Council Task" etc.
      # @example
      #   ActiveSpell.update_spell_durations
      def self.update_spell_durations
        begin
          respond "[infomon] updating spell durations..." if $infomon_debug
          spell_update_names, spell_update_durations = ActiveSpell.get_spell_info
          respond "#{spell_update_names}\r\n" if $infomon_debug
          respond "#{spell_update_durations}\r\n" if $infomon_debug

          existing_spell_names = []
          active_spells = Spell.active
          ignore_spells = ["Berserk", "Council Task", "Council Punishment", "Briar Betrayer"]
          active_spells.each { |s| existing_spell_names << s.name }
          inactive_spells = existing_spell_names - ignore_spells - spell_update_names
          inactive_spells.reject! do |s|
            s =~ /^Aspect of the \w+ Cooldown|^[\w\s]+ Recovery/
          end
          inactive_spells.each do |s|
            badspell = Spell[s].num
            Spell[badspell].putdown if Spell[s].active?
          end

          spell_update_durations.uniq.each do |k, v|
            if (spell = Spell.list.find { |s| (s.name.downcase == k.strip.downcase) || (s.num.to_s == k.strip) })
              if (spell.circle.to_i == 10) and not active_spells.any? { |s| s.circle.to_i == 10 }
                Spellsong.renewed
              end
              spell.active = true
              spell.timeleft = if v - Time.now > 300 * 60
                                 600.01
                               else
                                 ((v - Time.now) / 60)
                               end
            elsif $infomon_debug
              respond "no spell matches #{k}"
            end
          end
          show_duration_change if show_durations?
        rescue StandardError => e
          if $infomon_debug
            respond 'Error in spell durations thread'
            respond e.inspect
          end
        end
      end

      # Requests an update to spell durations by adding current time to the queue
      #
      # @return [void]
      # @example
      #   ActiveSpell.request_update
      def self.request_update
        queue << Time.now
      end

      # Returns the queue used for spell update requests
      #
      # @return [Queue] The queue object handling spell update requests
      # @example
      #   queue = ActiveSpell.queue
      def self.queue
        @queue ||= Queue.new
      end

      # Blocks execution until a spell update is requested
      #
      # @return [Time] The timestamp of the update request
      # @example
      #   event_time = ActiveSpell.block_until_update_requested
      def self.block_until_update_requested
        event = queue.pop
        queue.clear
        event
      end

      # Starts a monitoring thread that watches for spell updates
      #
      # @return [Thread] The monitoring thread
      # @raise [StandardError] If there's an error in the monitoring thread
      # @example
      #   ActiveSpell.watch!
      # @note Creates a persistent thread that continuously monitors for spell updates
      def self.watch!
        @thread ||= Thread.new do
          loop do
            block_until_update_requested
            update_spell_durations
          rescue StandardError => e
            respond 'Error in spell durations thread'
            respond e.inspect
          end
        end
      end
    end
  end
end