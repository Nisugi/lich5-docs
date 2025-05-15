module Lich
  module DragonRealms
    # Module for Dragon Realms spell casting and magic-related functionality
    module DRCA
      module_function

      # Regular expressions for detecting successful cyclic spell releases
      @@cyclic_release_success_patterns = [
        # Ranger spells
        /^The world seems to accelerate around you as the spirit of the cheetah escapes you/, # Cheetah Swiftness
        /^You feel distinctly frail and vulnerable as the spirit of the bear leaves you/, # Bear Strength
        /^The forces of nature that you roused are no longer with you/, # Awaken Forest
        # Empath spells
        /^Aesandry Darlaeth loses cohesion, returning your reaction time to normal/, # Aesandry Darlaeth
        /^You sense your hold on your Guardian Spirit weaken, then evaporate entirely/, # Guardian Spirit
        /^The signs of empathic atrocity escape to the deepest pits of your personality, your touch no longer deadly/, # Icutu Zaharenela
        /^The tingling across your body diminishes as you feel the motes of energy fade away/, # Regenerate
        # Bard spells
        /^You sing, purposely warbling some of the held notes for effec/, # Abandoned Heart (ABAN)
        /^The final tones of your enchante end with an abrupt flourish that leaves stark silence in its wake/, # Aether Wolves (AEWO)
        /^With a rising crescendo in your voice, you reprise the strong lines of the chorus of Albreda's Balm before bringing it to an abrupt conclusion/, # Albreda's Balm (ALB)
        /^The final, quiet notes of Blessing of the Fae stir the air gently, and die away/, # Blessing of the Fae (BOTF)
        /^The warm air swirling around you stills and begins to cool/, # Caress of the Sun (CARE)
        /^A few fleeting, soporific notes tarry in the air before your lullaby slowly dies down like the night receding at Anduwen/, # Damaris' Lullaby (DALU)
        /^You no longer feel the clarity of vision you had, as shadows creep across the area/, # Eye of Kertigen (EYE)
        /^You let your voice fade even as the pace of Faenella's Grace slows, winding down to a quiet conclusion/, # Faenella's Grace (FAE)
        /^The aethereal static subsides, returning your spellcasting abilities to normal/, # Glythtide's Joy (GJ)
        /^As your rendition of Hodierna's Lilt winds down to a close, you let each note linger on the air a moment, drawing out the final moment with a reluctance to let the soothing melody fade/, # Hodierna's Lilt (HODI)
        /^You build the final notes of Phoenix's Pyre with an upward scale that rises into a steep crescendo, and end with an abrupt silence/, # Phoenix's Pyre (PYRE)
        /^The dome of light extinguishes as the final notes of music die away/, # Sanctuary
        # Warrior Mage spels
        /^The dark mantle of aether surrounding you fades away/, # Aether Cloak (AC)
        /^You release your connection to the Elemental Plane of Electricity, allowing the static electricity to dissipate/, # Electrostatic Eddy (EE)
        /^Your link to the Fire Rain matrix has been severed/, # Fire Rain (FR)
        /^The chilling vapor surrounding you dissipates slowly/, # Rimefang (spell) (RIM)
        /^The frost-covered blade circling around you shatters into a fine icy mist/, # Rimefang (spell) (RIM)
        /^The jagged stone spears surrounding you at .* range tremble slightly, then crumble into a grey dust that is quickly reclaimed by the earth/, # Ring of Spears (ROS)
        # Cleric spells
        /^The deadening murk around you subsides/, # Hydra Hex (HYH)
        /^The dark patch of grime around you subsides/, # Hydra Hex (HYH)
        /^You sense the dark presence depart/, # Soul Attrition (SA)
        # Resurrection (REZZ) does not have messaging that makes it usable here.
        /^The heightened sense of spiritual awareness leaves you/, # Revelation (REV)
        /^The swirling fog dissipates from around you/, # Ghost Shroud (GHS)
        # Paladin spells
        /^The holy golden radiance of your soul subsides, retreating into your body/, # Holy Warrior (HOW)
        /^Truffenyi's Rally ends, leaving behind a momentary sensation of something stuck in your throat/, # Truffenyi's Rally (TR)
        # Moon Mage spells
        /^The web of shadows twitches one last time and then goes inert/, # Shadow Web (SHW)
        /^You release your mental hold on the lunar energy that sustains your moongate/, # Moongate (MG)
        /^The refractive field surrounding you fades away/, # Steps of Vuan (SOV)
        /^A \w+ brilliant \w+ sphere suddenly flares with a cold light and vaporizes/, # Starlight Sphere (SLS)
        # Trader spells
        /^Your calligraphy of light assailing/, # Arbiter's Stylus (ARS)
        /^The .* moonsmoke blows away from your face/, # Mask of the Moons (MOM)
        # Necromancer spells
        /^The Rite of Contrition matrix loses cohesion, leaving your aura naked/, # Rite of Contrition (ROC)
        /^The Rite of Forbearance matrix loses cohesion, leaving you to wallow in temptation/, # Rite of Forbearance (ROF)
        /^The Rite of Grace matrix loses cohesion, leaving your body exposed/, # Rite of Grace (ROG)
        /^The greenish hues about you vanish as the Universal Solvent matrix loses its cohesion/, # Universal Solvent (USOL)
        /^You sense your Call from Within spell weaken and disperse/ # Call from Within (CFW)
      ]

      # Infuses Osrel Meraud with mana
      # @param harness [Boolean] Whether to harness mana before infusing
      # @param amount [Integer] Amount of mana to infuse
      # @return [void]
      # @note Only works if Osrel Meraud is active and below 90 power
      def infuse_om(harness, amount)
        return unless DRSpells.active_spells['Osrel Meraud'] && DRSpells.active_spells['Osrel Meraud'] < 90
        return unless amount

        success = ['having reached its full capacity', 'A sense of fullness', 'Something in the area is interfering with your attempt to harness']
        failure = ['as if it hungers for more', 'Your infusion fails completely', 'You don\'t have enough harnessed mana to infuse that much', 'You have no harnessed']

        loop do
          pause 5 while DRStats.mana <= 40
          harness_mana([amount]) if harness
          break if success.include?(DRC.bput("infuse om #{amount}", success, failure))

          pause 0.5
          waitrt?
        end
      end

      # Attempts to harness a specific amount of mana
      # @param mana [Integer] Amount of mana to harness
      # @return [Boolean] True if harness was successful, false otherwise
      def harness?(mana)
        result = DRC.bput("harness #{mana}", 'You tap into', 'Strain though you may')
        pause 0.5
        waitrt?
        return result =~ /You tap into/
      end

      # Harnesses multiple amounts of mana in sequence
      # @param amounts [Array<Integer>] Array of mana amounts to harness
      # @return [void]
      def harness_mana(amounts)
        amounts.each do |mana|
          break unless harness?(mana)
        end
      end

      # Starts khri abilities
      # @param khris [Array<String>] List of khri abilities to activate
      # @param settings [OpenStruct] Settings containing khri configuration
      # @return [void]
      def start_khris(khris, settings)
        khris
          .each do |khri_set|
            activate_khri?(settings.kneel_khri, khri_set)
          end
      end

      # Activates a khri ability
      # @param settings_kneel [Boolean|Array] Whether to kneel for the khri
      # @param ability [String] Name of khri ability to activate
      # @return [Boolean] True if activation was successful
      def activate_khri?(settings_kneel, ability)
        abilities = ability.split.map(&:capitalize)

        # Standardize for with/without 'Khri' on the front
        abilities = abilities.drop(1) if abilities.first.casecmp('khri') == 0

        # Handling for 'Delay'
        should_delay = abilities.first.casecmp('delay') == 0
        abilities = abilities.drop(1) if should_delay

        # Check each khri in the list against Active Spells, Drop any that are active
        needed_abilities = abilities.select { |ability_to_check| DRSpells.active_spells["Khri #{ability_to_check}"].nil? }
        return true if needed_abilities.empty?

        kneel = needed_abilities.any? { |ability_to_check| kneel_for_khri?(settings_kneel, ability_to_check) }
        DRC.retreat if kneel
        DRC.bput('kneel', 'You kneel', 'You are already', 'You rise', "While swimming?  Don't be silly") if kneel && !kneeling?

        result = DRC.bput("Khri #{should_delay ? 'Delay ' : ''}#{needed_abilities.join(' ')}", get_data('spells').khri_preps)
        waitrt?
        DRC.fix_standing

        return ['Your mind and body are willing', 'Your body is willing', 'You have not recovered'].none?(result)
      end

      # Helper method to determine if kneeling is required for a khri
      # @param kneel [Boolean|Array] Kneel settings
      # @param ability [String] Ability name
      # @return [Boolean] True if kneeling required
      def kneel_for_khri?(kneel, ability)
        if kneel.is_a? Array
          kneel.map(&:downcase).include? ability.downcase.sub('khri ', '')
        else
          kneel
        end
      end

      # Starts barbarian abilities
      # @param abilities [Array<String>] List of abilities to activate
      # @param settings [OpenStruct] Settings containing meditation configuration
      # @return [void]
      def start_barb_abilities(abilities, settings)
        abilities.each { |name| activate_barb_buff?(name, settings.meditation_pause_timer, settings.sit_to_meditate) }
      end

[... Rest of code continues with documentation above each method ...]