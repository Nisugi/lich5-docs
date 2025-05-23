module Lich
  module Util
    module Magicinfo
      _respond "Landed in Magicinfo" if $infomon_debug

      @circle_state = Lich.magicinfo_circle
      @bonus_state = Lich.magicinfo_bonus
      @gift_state = Lich.magicinfo_gift
      @messages_state = Lich.magicinfo_messages # for future need

      # Handles requests for various magic commands.
      #
      # @param type [String] The type of request to handle. Defaults to 'announce'.
      # @return [void]
      # @raise [StandardError] Raises an error for unrecognized command types.
      # @example
      #   Lich::Util::Magicinfo.request('help')
      def self.request(type = 'announce')
        case type
        when /help/
          self.help # Ok, that's just wrong.
        when /announce/
          self.announce
        when /clear(?:\s+(.*)|$)/
          if $1.nil?
            self.clear(nil)
          else
            dump = $1.dup
            self.clear(dump)
          end
        when /circle/
          self.circle
        when /messages/
          self.messages
        when /bonus/
          self.bonus
        when /gift/
          self.gift
        when /set (.*)/
          if $1.nil?
            self.set(nil)
          else
            pump = $1.dup
            self.set(pump)
          end
        when /update|save|load/
          self.deprecated
        else
          _respond; _respond "Magic error! Type ';magic help' for usage information."; _respond
        end
      end

      # Displays help information for magic commands.
      #
      # @return [void]
      # @example
      #   Lich::Util::Magicinfo.help
      def self.help
        respond
        respond 'Magic usage:'
        respond '   ;magic                     - Shows your active spells and their durations.'
        respond "   ;magic set [spell#] [mins] - Sets a spell's duration."
        respond '   ;magic clear [spell]       - Remove a single spell.'
        respond '   ;magic clear               - Clears the whole list.'
        respond '   ;magic circles             - Toggles the display of spell circle labels with the active spell list.'
        respond '   ;magic bonuses             - Toggles the display of spell bonuses with the active spell list.'
        respond '   ;magic gift                - Toggles the display of Gift of Lumnis information with the active spell list.'
        respond '   ;magic messages            - Toggles the display of a duration message after each cast.'
        respond
      end

      # Clears the active spell list or a specific spell.
      #
      # @param rd [String, nil] The spell identifier to clear. If nil, clears all spells.
      # @return [void]
      # @raise [StandardError] Raises an error if the spell cannot be identified.
      # @example
      #   Lich::Util::Magicinfo.clear('1')
      def self.clear(rd)
        # requested_drop = rd
        if rd.nil? or rd.empty?
          while (spell = Spell.active.first)
            spell.putdown
          end
          Spell.active.clear
          respond('Active spell list cleared.')
        else
          if rd.to_i == 0
            spell = Spell[rd]
          else
            spell = Spell[rd.to_i]
          end
          if spell.nil?
            respond("Could not identify spell #{$1}")
          else
            spell.putdown
            respond("#{spell} has been removed from the list.")
          end
        end
      end

      # Toggles the display of spell circle labels in the active spell list.
      #
      # @return [void]
      # @example
      #   Lich::Util::Magicinfo.circle
      def self.circle
        if @circle_state == false
          Lich.magicinfo_circle = true
          @circle_state = true
          respond('Spell circle labels will be displayed in the active spell list.')
        else
          Lich.magicinfo_circle = false
          @circle_state = false
          respond('Spell circle labels will not be displayed in the active spell list.')
        end
      end

      # Toggles the display of spell duration messages after each cast.
      #
      # @return [void]
      # @example
      #   Lich::Util::Magicinfo.messages
      def self.messages
        # if $infomon_values['show_messages'] == false
        #   $infomon_values['show_messages'] = true
        #   respond('Showing spell duration messages after each cast is now on.')
        # else
        #   $infomon_values['show_messages'] = false
        #   respond('Showing spell duration messages after each cast is now off.')
        # end
        respond('This command may be coming soon!')
      end

      # Toggles the display of spell bonuses in the active spell list.
      #
      # @return [void]
      # @example
      #   Lich::Util::Magicinfo.bonus
      def self.bonus
        if @bonus_state == false
          Lich.magicinfo_bonus = true
          @bonus_state = true
          respond('Spell bonuses will be displayed in the active spell list.')
        else
          Lich.magicinfo_bonus = false
          @bonus_state = false
          respond('Spell bonuses will not be displayed in the active spell list.')
        end
      end

      # Toggles the display of the Gift of Lumnis in the active spell list.
      #
      # @return [void] This method does not return a value.
      # @note This method maintains the state of the gift display.
      # @example
      #   Lich::Util::Magicinfo.gift
      def self.gift
        if @gift_state == false
          Lich.magicinfo_gift = true
          @gift_state = true
          respond('Gift of Lumnis will be displayed in the active spell list.')
        else
          Lich.magicinfo_gift = false
          @gift_state = false
          respond('Gift of Lumnis will not be displayed in the active spell list.')
        end
      end

      # Notifies that the setting is deprecated and no longer in use.
      #
      # @return [void] This method does not return a value.
      # @example
      #   Lich::Util::Magicinfo.deprecated
      def self.deprecated
        respond('this setting is no longer used')
      end

      # Sets the spell based on the provided request actions.
      #
      # @param ra [String] The request actions containing the spell number and optional time left.
      # @return [void] This method does not return a value.
      # @raise [ArgumentError] If the spell number is invalid or cannot be found.
      # @example
      #   Lich::Util::Magicinfo.set("1 10")
      def self.set(ra)
        request_actions = ra
        if request_actions.nil?
          respond("Magic error! Type ';magic help' for usage information.")
        else
          set_request_elements = request_actions.split
          if set_request_elements[0].to_i == 0
            respond("Use the spell number for accuracy. Type ';magic help' for usage information.")
          else
            spell = Spell[set_request_elements[0].to_i]
          end
          if spell.nil?
            respond("Magic error! Requested spell cannot be found.")
          else
            spell.putup
            spell.timeleft = set_request_elements[1].to_i
            respond set_request_elements.length
            respond("Spell '#{spell}' is now set as having #{spell.timeleft} minutes left.")
          end
        end
      end

      # Announce the active spells and their bonuses.
      #
      # This method generates a formatted string that lists all active spells,
      # their bonuses, and totals for offense, defense, stats, and skills.
      # If there are no active spells, it indicates that as well.
      #
      # @return [String] the formatted announcement of active spells and their bonuses.
      # @raise [StandardError] if there is an issue with spell data retrieval.
      # @example
      #   Lich::Util::Magicinfo.announce
      #   # => Outputs a string with active spells and their bonuses.
      def self.announce
        output = String.new
        if Spell.active.empty?
          output.concat("\r\n(no active spells)\r\n")
        else
          lastcircle = nil
          Spell.active.compact!
          total_boltAS, total_physicalAS, total_boltDS, total_physicalDS, total_elementalCS, total_mentalCS, total_spiritCS, total_sorcererCS, total_elementalTD, total_mentalTD, total_spiritTD, total_sorcererTD, total_strength, total_dodging, total_combatmaneuvers, total_damagefactor, total_block, total_constitution, total_health, total_uaf, total_asg, total_fof_offset = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
          Spell.active.sort_by { |spell| spell.num.to_i }.each { |spell|
            if @circle_state and (spell.circle != lastcircle) then output.concat("\r\n- #{spell.circlename}:\r\n") end
            bonus_string = ' - '
            if @bonus_state
              if spell.bolt_as != 0
                bonus_string.concat "#{spell.bolt_as} bAS, "
                total_boltAS += spell.bolt_as
              end
              if spell.physical_as != 0
                bonus_string.concat "#{spell.physical_as} pAS, "
                total_physicalAS += spell.physical_as
              end
              if spell.bolt_ds != 0
                bonus_string.concat "#{spell.bolt_ds} bDS, "
                total_boltDS += spell.bolt_ds
              end
              if spell.physical_ds != 0
                bonus_string.concat "#{spell.physical_ds} pDS, "
                total_physicalDS += spell.physical_ds
              end
              if spell.elemental_cs != 0
                bonus_string.concat "#{spell.elemental_cs} elemCS, "
                total_elementalCS += spell.elemental_cs
              end
              if spell.spirit_cs != 0
                bonus_string.concat "#{spell.spirit_cs} spirCS, "
                total_spiritCS += spell.spirit_cs
              end
              if spell.sorcerer_cs != 0
                bonus_string.concat "#{spell.sorcerer_cs} sorcCS, "
                total_sorcererCS += spell.sorcerer_cs
              end
              if spell.elemental_td != 0
                bonus_string.concat "#{spell.elemental_td} elemTD, "
                total_elementalTD += spell.elemental_td
              end
              if spell.mental_td != 0
                bonus_string.concat "#{spell.mental_td} mentTD, "
                total_mentalTD += spell.mental_td
              end
              if spell.spirit_td != 0
                bonus_string.concat "#{spell.spirit_td} spirTD, "
                total_spiritTD += spell.spirit_td
              end
              if spell.sorcerer_td != 0
                bonus_string.concat "#{spell.sorcerer_td} sorcTD, "
                total_sorcererTD += spell.sorcerer_td
              end
              if spell.strength.to_i != 0
                bonus_string.concat "#{spell.strength} str, "
                total_strength += spell.strength.to_i
              end
              if spell.dodging.to_i != 0
                bonus_string.concat "#{spell.dodging} dodge, "
                total_dodging += spell.dodging.to_i
              end
              if spell.combatmaneuvers.to_i != 0
                bonus_string.concat "#{spell.combatmaneuvers} CM, "
                total_combatmaneuvers += spell.combatmaneuvers.to_i
              end
              if spell.damagefactor.to_i != 0
                bonus_string.concat "#{spell.damagefactor}% DF, "
                total_damagefactor += spell.damagefactor.to_i
              end
              if spell.block.to_i != 0
                bonus_string.concat "#{spell.block}% block, "
                total_block += spell.block.to_i
              end
              if spell.constitution.to_i != 0
                bonus_string.concat "#{spell.constitution} con, "
                total_constitution += spell.constitution.to_i
              end
              if spell.health.to_i != 0
                bonus_string.concat "#{spell.health} health, "
                total_health += spell.health.to_i
              end
              if spell.unarmed_af.to_i != 0
                bonus_string.concat "#{spell.unarmed_af} UAF, "
                total_uaf += spell.unarmed_af.to_i
              end
              if spell.asg.to_i != 0
                bonus_string.concat "#{spell.asg} AsG, "
                total_asg += spell.asg.to_i
              end
              begin
                if spell.fof_offset.to_i != 0
                  bonus_string.concat "#{spell.fof_offset} FoF offset, "
                  total_fof_offset += spell.fof_offset.to_i
                end
              rescue
                nil
              end
            end
            output.concat(sprintf("  %04s:  %-023s - %s%s\r\n", spell.num.to_s, spell.name, spell.remaining, bonus_string.chop.chop))
            lastcircle = spell.circle
          }
          output.concat("\r\n")
          if @bonus_state
            total_offense_string = ''
            total_defense_string = ''
            total_stat_string    = ''
            total_skill_string   = ''

            total_offense_string = total_offense_string + total_boltAS.to_s + ' bAS, ' if total_boltAS != 0
            total_offense_string = total_offense_string + total_physicalAS.to_s + ' pAS, ' if total_physicalAS != 0
            total_offense_string = total_offense_string + total_elementalCS.to_s + ' elemCS, ' if total_elementalCS != 0
            total_offense_string = total_offense_string + total_mentalCS.to_s + ' mentCS, ' if total_mentalCS != 0
            total_offense_string = total_offense_string + total_spiritCS.to_s + ' spirCS, ' if total_spiritCS != 0
            total_offense_string = total_offense_string + total_sorcererCS.to_s + ' sorcCS, ' if total_sorcererCS != 0
            total_offense_string = total_offense_string + total_damagefactor.to_s + '% DF ' if total_damagefactor != 0
            total_offense_string = total_offense_string + total_uaf.to_s + ' UAF, ' if total_uaf != 0
            total_offense_string.chop!.chop!

            total_defense_string = total_defense_string + total_boltDS.to_s + ' bDS, ' if total_boltDS != 0
            total_defense_string = total_defense_string + total_physicalDS.to_s + ' pDS, ' if total_physicalDS != 0
            total_defense_string = total_defense_string + total_elementalTD.to_s + ' elemTD, ' if total_elementalTD != 0
            total_defense_string = total_defense_string + total_mentalTD.to_s + ' mentTD, ' if total_mentalTD != 0
            total_defense_string = total_defense_string + total_spiritTD.to_s + ' spirTD, ' if total_spiritTD != 0
            total_defense_string = total_defense_string + total_sorcererTD.to_s + ' sorcTD, ' if total_sorcererTD != 0
            total_defense_string = total_defense_string + total_block.to_s + '% block, ' if total_block != 0
            total_defense_string = total_defense_string + total_asg.to_s + ' AsG, ' if total_asg != 0
            total_defense_string = total_defense_string + total_fof_offset.to_s + ' FoF offset, ' if total_fof_offset != 0
            total_defense_string.chop!.chop!

            total_stat_string = total_stat_string + total_strength.to_s + ' str, ' if total_strength != 0
            total_stat_string = total_stat_string + total_constitution.to_s + ' con, ' if total_constitution != 0
            total_stat_string = total_stat_string + total_health.to_s + ' health, ' if total_health != 0
            total_stat_string.chop!.chop!

            total_skill_string = total_skill_string + total_dodging.to_s + ' dodge, ' if total_dodging != 0
            total_skill_string = total_skill_string + total_combatmaneuvers.to_s + ' CM, ' if total_combatmaneuvers != 0
            total_skill_string.chop!.chop!

            output.concat("- Totals:\r\n")
            output.concat("  Offense: #{total_offense_string}\r\n") if total_offense_string.length > 0
            output.concat("  Defense: #{total_defense_string}\r\n") if total_defense_string.length > 0
            output.concat("    Stats: #{total_stat_string}\r\n") if total_stat_string.length > 0
            output.concat("   Skills: #{total_skill_string}\r\n") if total_skill_string.length > 0
            output.concat("\r\n")
          end
        end
        respond output
        if @gift_state
          string_to_send = 'lumnis info'
          do_client("#{string_to_send}")
        end
      end
    end # Magicinfo
  end # Util
end # Lich