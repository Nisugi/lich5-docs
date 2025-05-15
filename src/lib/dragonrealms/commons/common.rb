# Core utility module for DragonRealms functionality
# @author Lich5 Documentation Generator
module Lich
  # DragonRealms-specific utility methods and classes
  module DragonRealms
    # Core utility methods for DragonRealms scripts
    module DRC
      $pause_all_lock ||= Mutex.new
      $safe_pause_lock ||= Mutex.new

      module_function

      # Executes a command and waits for a matching response with retries and error handling
      #
      # @param message [String] The command to send to the game
      # @param matches [Array<String,Regexp>] Patterns to match in the response
      # @param options [Hash] Additional options
      # @option options [Integer] :timeout (15) Max seconds to wait for match
      # @option options [Boolean] :ignore_rt (false) Whether to ignore roundtime
      # @option options [Boolean] :suppress_no_match (false) Whether to suppress timeout message
      # @option options [Boolean] :debug (false) Whether to output debug info
      # @return [String] The matched response text
      def bput(message, *matches)
        options = (matches.shift if matches.first.is_a?(Hash)) || {}
        options['timeout'] ||= 15
        options['ignore_rt'] ||= false

        timeout = options['timeout']
        ignore_rt = options['ignore_rt']
        suppress = options['suppress_no_match']

        if options['debug']
          echo "bput.message=#{message}"
          echo "bput.options=#{options}"
          echo "bput.matches=#{matches}"
        end

        waitrt? unless ignore_rt
        log = []
        matches.flatten!
        matches.map! { |item| item.is_a?(Regexp) ? item : /#{item}/i }
        clear
        put message
        timer = Time.now
        while (response = get?) || (Time.now - timer < timeout)

          if response.nil?
            pause 0.1
            next
          end

          log += [response]

          case response
          when /(?:\.\.\.wait |Wait |\.\.\. wait )([0-9]+)/
            unless ignore_rt
              pause(Regexp.last_match(1).to_i - 0.5)
              waitrt?
              put message
              timer = Time.now
            end
            next
          when /Sorry, you may only type ahead/
            pause 1
            put message
            timer = Time.now
            next
          when /^You can't do that while you are asleep./
            put 'wake'
            put message
            timer = Time.now
            next
          when /^You are a bit too busy performing to do that/, /^You should stop playing before you do that/
            put 'stop play'
            put message
            timer = Time.now
            next
          when /would give away your hiding place/
            release_invisibility
            put 'unhide'
            put message
            timer = Time.now
            next
          when /^You don't seem to be able to move to do that/
            next unless matches.include?(response)
          when /^You are still stunned/
            pause 0.5 while stunned?
            pause 0.5
            put message
            timer = Time.now
            next
          when /^You can't do that while entangled in a web/
            pause 0.5 while webbed?
            pause 0.5
            put message
            timer = Time.now
            next
          when /^You must be standing/, /^You should stand up first/, /^You'll need to stand up first/, /^You can't do that while (sitting|kneeling|lying)/, /^You should be sitting up/, /^You really should be standing to play/, /^After failing to draw a breath for what feels like forever/
            fix_standing
            waitrt?
            put message
            timer = Time.now
            next
          end

          matches.each do |match|
            if (result = response.match(match))
              return result.to_a.first
            end
          end
        end

        unless suppress
          echo "*** No match was found after #{timeout} seconds, dumping info"
          echo "messages seen length: #{log.length}"
          log.reverse.each { |logged_response| echo "message: #{logged_response}" }
          echo "checked against #{matches}"
          echo "for command #{message}"
        end

        ''
      end

      # Waits for a script to complete execution
      #
      # @param name [String] Name of script to run
      # @param args [Array] Arguments to pass to script
      # @param flags [Hash] Script flags
      # @return [Script] Handle to completed script
      def wait_for_script_to_complete(name, args = [], flags = {})
        verify_script(name)
        script_handle = start_script(name, args.map { |arg| arg.to_s =~ /\s/ ? "\"#{arg}\"" : arg }, flags)
        if script_handle
          pause 2
          pause 0.5 while Script.running.include?(script_handle)
        end
        script_handle
      end

      # Checks if you can see the sky from current location
      #
      # @return [Boolean] true if sky is visible, false if not
      def can_see_sky?
        # If you are indoors and not able to see the sky.
        inside_no_sky = "That's a bit hard to do while inside."
        # If you are indoors but able to see the sky (e.g. a window or skylight).
        inside_yes_sky = "You glance outside"
        # If you are outdoors.
        outside = "You glance up at the sky"
        # Can we see the sky?
        bput("weather", inside_no_sky, inside_yes_sky, outside) != inside_no_sky
      end

      # Attempts to forage for an item with retries
      #
      # @param item [String] Item to forage for
      # @param tries [Integer] Number of attempts
      # @return [Boolean] Whether forage was successful
      def forage?(item, tries = 5)
        snapshot = "#{right_hand}#{left_hand}"
        while snapshot == "#{right_hand}#{left_hand}"
          tries > 0 ? tries -= 1 : (return false)
          case bput("forage #{item}", 'Roundtime', 'The room is too cluttered to find anything here', 'You really need to have at least one hand free to forage properly', 'You survey the area and realize that any foraging efforts would be futile')
          when 'The room is too cluttered to find anything here'
            return false unless kick_pile?
          when 'You survey the area and realize that any foraging efforts would be futile'
            return false
          when 'You really need to have at least one hand free to forage properly'
            echo 'WARNING: hands not emptied properly. Stowing...'
            fput('stow right')
          end
          waitrt?
        end
        true
      end

      # Attempts to collect items from the ground
      #
      # @param item [String] Item to collect
      # @param practice [Boolean] Whether to use practice mode
      def collect(item, practice = true)
        messages = [
          'As you rummage around',
          'believe you would probably have better luck trying to find a dragon',
          'if you had a bit more luck',
          'The room is too cluttered',
          'one hand free to properly collect',
          'You are sure you knew',
          'You begin to forage around,',
          'You begin scanning the area before you',
          'You begin exploring the area, searching for',
          'You find something dead and lifeless',
          'You cannot collect anything',
          'you fail to find anything',
          'You forage around but are unable to find anything',
          'You manage to collect a pile',
          'You survey the area and realize that any collecting efforts would be futile',
          'You wander around and poke your fingers',
          'You forage around for a while and manage to stir up a small mound of fire ants!'
        ]

        practicing = "practice" if practice

        case bput("collect #{item} #{practicing}", messages)
        when 'The room is too cluttered'
          return unless kick_pile?

          collect(item)
        end
        waitrt?
      end

      # Kicks a pile to clear room clutter
      #
      # @param item [String] Type of pile to kick
      # @return [Boolean] Whether kick was successful
      def kick_pile?(item = 'pile')
        fix_standing
        return unless DRRoom.room_objs.any? { |room_obj| room_obj.match?(/pile/) }
        bput("kick #{item}", 'I could not find', 'take a step back and run up to', 'Now what did the .* ever do to you', 'You lean back and kick your feet,') == 'take a step back and run up to'
      end

      # Searches a container for items matching parameters
      #
      # @param parameter [String] Search parameter (B/SC/etc)
      # @param container [String] Container to search in
      # @return [Array<String>] Matching items found
      def rummage(parameter, container)
        result = DRC.bput("rummage /#{parameter} my #{container}", 'but there is nothing in there like that\.', 'looking for .* and see .*', 'While it\'s closed', 'I don\'t know what you are referring to', 'You feel about', 'That would accomplish nothing')

        case result
        when 'You feel about'
          release_invisibility
          return rummage(parameter, container)
        when 'but there is nothing in there like that.', 'While it\'s closed', 'I don\'t know what you are referring to', 'That would accomplish nothing'
          return []
        end

        text = result.match(/looking for .* and see (.*)\.$/).to_a[1]
        case parameter
        when 'B'
          box_list_to_adj_and_noun(text)
        when 'SC'
          scroll_list_to_adj_and_noun(text)
        else
          list_to_nouns(text)
        end
      end

      # Gets list of skins in a container
      #
      # @param container [String] Container to search
      # @return [Array<String>] List of skins found
      def get_skins(container)
        rummage('S', container)
      end

      # Gets list of gems in a container
      #
      # @param container [String] Container to search
      # @return [Array<String>] List of gems found
      def get_gems(container)
        rummage('G', container)
      end

      # Gets list of materials in a container
      #
      # @param container [String] Container to search
      # @return [Array<String>] List of materials found
      def get_materials(container)
        rummage('M', container)
      end

      # Splits a comma-separated list into an array
      #
      # @param list [String] Comma-separated list
      # @return [Array<String>] Array of items
      def list_to_array(list)
        list.strip.split(/(?:,|(?:, |\s)?and\s?)(?:\s?<pushBold\/>\s?)?(?=\s\ba\b|\s\ban\b|\s\bsome\b|\s\bthe\b)/i).reject(&:empty?)
      end

      # Extracts box names from a list
      #
      # @param list [String] List of boxes
      # @return [Array<String>] Array of box names
      def box_list_to_adj_and_noun(list)
        list.strip
            .split($box_regex)
            .reject(&:empty?)
            .select { |item| item =~ $box_regex }
            .map { |box| box.gsub('ironwood', 'iron') } # make all ironwood into iron because "the parser"
      end

      # Extracts scroll names from a list
      #
      # @param list [String] List of scrolls
      # @return [Array<String>] Array of scroll names
      def scroll_list_to_adj_and_noun(list)
        list_to_array(list).map { |entry|
          entry
            .sub(/(an|some|a(?: piece of)?)\s/, '')
            .sub(/\slabeled with.*/, '')
            .sub(/icy blue vellum scroll/, 'icy scroll')
            .sub(/green vellum scroll/, 'green scroll')
            .sub(/fetid antelope vellum/, 'antelope vellum')
            .sub(/papyrus roll/, 'papyrus.roll')
            .sub(/pallid red scroll/, 'pallid scroll')
            .sub(/\s(bark|leaf|ostracon|papyrus|parchment|roll|scroll|tablet|vellum|manuscript)\s.*/, ' \1')
            .sub(/crumpled paper/, 'crumpled')
            .sub(/pale ricepaper/, 'pale')
            .sub(/stormy grey/, 'stormy')
            .sub(/mossy green/, 'mossy')
            .sub(/dark purple/, 'dark')
            .sub(/vibrant red/, 'vibrant')
            .sub(/bright green/, 'bright')
            .sub(/icy blue/, 'blue')
            .sub(/pearl-white silk/, 'silk')
            .sub(/ghostly white/, 'white')
            .sub(/crinkled violet/, 'crinkled')
            .sub(/drawing paper/, 'drawing')
            .strip
        }
      end

      # Extracts nouns from a list of items
      #
      # @param list [String] List of items
      # @return [Array<String>] Array of nouns
      def list_to_nouns(list)
        list_to_array(list)
          .map { |long_name| get_noun(long_name) }
          .compact
          .reject { |noun| noun == '' }
      end

      # Gets the noun from an item name
      #
      # @param long_name [String] Full item name
      # @return [String] Just the noun
      def get_noun(long_name)
        remove_flavor_text(long_name).strip.scan(/[a-z\-']+$/i).first
      end

      # Removes flavor text from item descriptions
      #
      # @param item [String] Item description
      # @return [String] Clean item name
      def remove_flavor_text(item)
        # link is to online regex expression tester
        # https://regex101.com/r/4lGY6u/13
        item.sub(/\s?\b(?:(?:colorfully and )?(?:artfully|artistically|attractively|beautifully|bl?ack-|cleverly|clumsily|crudely|deeply|delicately|edged|elaborately|faintly|flamboyantly|front-|fully|gracefully|heavily|held|intricately|lavishly|masterfully|plentifully|prominantly|roughly|securely|sewn|shabbily|shadow-|simply|somberly|skillfully|sloppily|starkly|stitched|tied and|tightly|well-)\s?)?(?:accented|accentuated|acid-etched|adorned|affixed|appliqued|assembled|attached|augmented|awash|backed|back-laced|balanced|banded|batiked|beaded|bearded|bearing|bedazzled|bedecked|bejeweled|beset|bestrewn|blazoned|bordered|bound|braided|branded|brocaded|bristling|brushed|buckled|burned|buttoned|caked|camouflaged|capped|carved|caught|centered|chased|chiseled|cinched|circled|clasped|cloaked|closed|coated|cobbled together|coiled|colored|composed|concealed|connected|constructed|countoured|covered|crafted|crested|crisscrossed|crowded|crowned|cuffed|cut|dangling|dappled|decked|decorated|deformed|depicting|designed|detailed|discolored|displaying|divided|done|dotted|draped|drawn|dressed|drizzled|dusted|edged|elaborately|embedded|embell?ished|emblazed|emblazoned|embossed|embroidered(?: all over| painstakingly)?|enameled(?: across)?|encircled|encrusted|engraved|engulfed|enhanced|entwined|equipped|etched|fashioned(?: so)?|fastened|feathered|featuring|festooned|fettered|filed|filled|firestained|fit|fitted|fixed|flecked|fletched|forged|formed|framed|fringed|frosted|full|gathered|gleaming|glimmering|glittering|goldworked|growing|gypsy-set|hafted|hand-tooled|hanging|heavily(?:-beaded| covered)?|held fast|hemmed|hewn|hideously|highlighted|hilted|honed|hung|impressed|incised|ingeniously repurposed|inscribed|inlaid|inset|interlaced|interspersed|interwoven|jeweled|joined|laced(?: up)?|lacquered|laden|layered|limned|lined|linked|looped|knotted|made|marbled|marked|marred|meshed|mosaicked|mottled|mounted|oiled|oozing|outlined|ornamented|overlai(?:d|n)|padded|painted|paired|patched|pattern-welded|patterned|pinned|plumed|polished|printed|reinforced|reminiscent|rendered|revealing|riddled|ridged|rimed|ringed|riveted|sashed|scarred|scattered|scorched|sculpted|sealed|seamed|secured|securely|set|sewn|shaped|shimmering|shod|shot|shrouded|side-laced|slashed|slung|smeared|smudged|spangled|speckled|spiraled|splatter-dyed|splattered|spotted|sprinkled|stacked|surmounted|surrounded|suspended|stained|stamped|starred|stenciled|stippled|stitched(?: together)?|strapped|streaked|strengthened|strewn|striated|striped|strung|studded|swathed|swirled|tailored|tangled|tapered|tethered|textured|threaded|tied|tightly|tinged|tinted|tipped|tooled|topped|traced|trimmed|twined|veined|vivified|washed|webbed|weighted|whorled|worked|worn|woven|wrapped|wreathed|wrought)?\b ["]?\b(?:a hand-tooled|across|along|an|around|atop|bearing|belted|bright streaks|dangling|designed|detailing|down (?:each leg|one side)|dyed (?:a|and|deep|of|in|night|rust|shimmering|the|to|with)|engravings|entitled|errant pieces|featuring|flaunting|frescoed|from|Gnomish Pride|(?:encased |quartered )?in(?: the)?|into|labeled|leading|like|lining|matching|(?<!stick|slice|chunk|flask|hunk|series|set|pair|piece) of|on|out|overlayed gleaming silver|resembling|shades of color|sporting|surrounding|that|the|through|tinged somber black|titled|to|upon|WAR MONGER|with|within|\b(?:at|bearing|(?:accented |held |secured )?by|carrying|clutching|colored|cradling|dangling|depicting|(?:prominently )?displaying|embossed|etched|featuring|for(?:ming)?|holding|(?<!slice |chunk |flask |hunk |series |set |pair |piece )of|over|patterned|striped|suspending|textured|that)\b \b(?:a (?:band|beaded|brass|cascade|cluster|coral|crown|dead|.+ (?:ingot|boulder|stone|rock|nugget)|fierce|fanged|fringe|glowing|golden|grinning|howling|large|lotus|mosaic|pair|poorly|rainbow|roaring|row|silver(?:y|weave)?|small|snarling|spray|tailored|thick|tiny|trio|turquoise|yellowed)|(?:squared )?agonite (?:links|decorated)|alternating|an|(?:purple |blue )?and|ash|beaded fringe|blackened (?:steel(?: accents| bearing| with|$)|ironwood)|blue (?:gold|steel)|burnished golden|cascading layers|carved ivory|chain-lined|chitinous|(?:deep red|dull black|pale blue) cloth|cloudberry blossoms|colorful tightly|cotton candy|crimson steel|crisscrossed|curious design|curved|crystaline charm|dark (?:blue|green|grey|metals|windsteel) (?:and|exuding|glaes|hues|khor'vela|muracite|pennon|with)|dark supple|deepest|deeply blending|delicate|dusky (?:dreamweave|green-grey)|ebonwood$|emblazoned|enamel?led (?:steel|bronze)|etched|fine(?:-grained| black| crushed)|finely wrought|flame-kissed|forest|fused-together|fuzzy grey|gauze atop|gilded steel|glass eyeballs|glistening green|golden oak|grey fur|hammered|haralun|has|heavy (?:grey|pearl|silver)|horn|Ilithi cedar|inky black|interlocking silver|interwoven|iridescent|jagged interlocking plates|(?:soft dark|supple|thick|woven) (?:bolts|leather)|lightweight|long swaths|lustrous|kertig ravens|made|metal cogs|mirror-finished|mottled|multiple woods|naphtha|oak|oblong sanguine|one|onyx buttons|opposing images|overlapping|pale cerulean|pallid links|pastel-hued|pins|pitted (?:black iron|steel)|plush velvet|polished (?:bronze|hemlock|steel)|raccoon tails|ram's horns|rat pelts|raw|red and blue|rich (?:purple|golden)|riveted bindings|roughened|rowan|sanguine thornweave|scattered star|scorch marks|sculpted|shadows|shark cartilage|shifting (?:celadon|shades)|shipboard|(?:braided |cobalt |deep black |desert-tan |dusky red Taisidon |ebony |exquisite spider|fine leaf-green |flowing night|glimmering ebony |heavy |marigold |pale gold marquisette and virid |rich copper |spiral-braided |steel|unadorned black Musparan )?silk(?:cress)?|(?:coiled |shimmering )?silver(?:steel| and |y)?|sirese blue spun glitter|six crossed|slender|small bones|smoothly interlocking|snow leopard|soft brushed|somber black|sprawled|sun-bleached|steel links|stones|strips of|sunny yellow|teardrop plates|telothian|the|tiny (?:golden|indurium|scales|skull)|tightly braided|tomiek|torn|twists|two|undyed|vibrant multicolored|viscous|waves of|weighted|well-cured|white ironwood|windstorm gossamer|wintry faeweave|woven diamondwood))\b.*/, '')
      end

      # Gets canonical town name from text
      #
      # @param text [String] Text containing town name
      # @return [String,nil] Canonical town name or nil if not found
      def get_town_name(text)
        towns = $HOMETOWN_REGEX_MAP.select { |_town, regex| regex =~ text }.keys
        if towns.length > 1
          DRC.message("Found multiple towns that match '#{text}': #{towns}")
          DRC.message("Using first town that matched: #{towns.first}")
          DRC.message("To avoid ambiguity, please use the town's full name: https://elanthipedia.play.net/Category:Cities")
        end
        towns.first
      end

      # Plays a beep sound
      def beep
        echo("\a")
      end

      # Ensures character is standing
      def fix_standing
        loop do
          break if standing?

          bput('stand', 'You stand', 'You are so unbalanced', 'As you stand', 'You are already', 'weight of all your possessions', 'You are overburdened and cannot', 'You\'re unconscious', 'You swim back up into a vertical position', "You don't seem to be able to move to do that", 'prevents you from standing', 'You\'re plummeting to your death', 'There\'s no room to do much of anything here')
        end
      end

      # Listens to a teacher
      #
      # @param teacher [String] Name of teacher
      # @param observe_flag [Boolean] Whether to observe
      # @return [Boolean] Whether successfully listening
      def listen?(teacher, observe_flag = false)
        return false if teacher.nil?
        return false if teacher.empty?

        bad_classes = %w[Thievery Sorcery]
        bad_classes += ['Life Magic', 'Holy Magic', 'Lunar Magic', 'Elemental Magic', 'Arcane Magic', 'Targeted Magic', 'Arcana', 'Attunement'] if DRStats.barbarian? || DRStats.thief?
        bad_classes += ['Utility'] if DRStats.barbarian?

        observe = observe_flag ? 'observe' : ''

        case bput("listen to #{teacher} #{observe}", 'begin to listen to \w+ teach the .* skill', 'already listening', 'could not find who', 'You have no idea', 'isn\'t teaching a class', 'don\'t have the appropriate training', 'Your teacher appears to have left', 'isn\'t teaching you anymore', 'experience differs too much from your own', 'but you don\'t see any harm in listening', 'invitation if you wish to join this class', 'You cannot concentrate to listen to .* while in combat')
        when /begin to listen to \w+ teach the (.*) skill/
          return true if bad_classes.grep(/#{Regexp.last_match(1)}/i).empty?

          bput('stop listening', 'You stop listening')
        when 'already listening'
          return true
        when 'but you don\'t see any harm in listening'
          bput('stop listening', 'You stop listening')
        end

        false
      end

      # Gets info about active teaching
      #
      # @return [Hash] Teacher names mapped to skills
      def assess_teach
        case bput('assess teach', 'is teaching a class', 'No one seems to be teaching', 'You are teaching a class')
        when 'No one seems to be teaching', 'You are teaching a class'
          waitrt?
          return {}
        end
        results = reget(20, 'is teaching a class')
        waitrt?

        results.each_with_object({}) do |line, hash|
          line.match(/(.*) is teaching a class on (.*) which is still open to new students/) do |match|
            teacher = match[1]
            skill = match[2]
            # Some classes match the first format, some have additional text in the 'skill' string that needs to be filtered
            skill.match(/.* \(compared to what you already know\) (.*)/) { |m| skill = m[1] }
            hash[teacher] = skill
          end
        end
      end

      # Attempts to hide
      #
      # @param hide_type [String] Type of hide command
      # @return [Boolean] Whether successfully hidden
      def hide?(hide_type = 'hide')
        unless hiding?
          case bput(hide_type, 'Roundtime', 'too busy performing', 'can\'t see any place to hide yourself', 'Stalk what', 'You\'re already stalking', 'Stalking is an inherently stealthy', 'You haven\'t had enough time', 'You search but find no place to hide')
          when 'too busy performing'
            bput('stop play', 'You stop playing', 'In the name of')
            return hide?(hide_type)
          when "You're already stalking"
            put 'stop stalk'
            return hide?(hide_type)
          when 'You haven\'t had enough time'
            pause 1
            return hide?(hide_type)
          end
          pause
          waitrt?
        end
        hiding?
      end

      # Cleans up item names from DR formatting
      #
      # @param string [String] Item name
      # @return [String] Cleaned name
      def fix_dr_bullshit(string)
        return string if string.split.length <= 2

        string.sub!(' and chain', '') if string =~ /ball and chain/

        string =~ /(\S+) .* (\S+)/
        "#{Regexp.last_match(1)} #{Regexp.last_match(2)}"
      end

      # Gets name of item in left hand
      #
      # @return [String,nil] Item name or nil if empty
      def left_hand
        GameObj.left_hand.name == 'Empty' ? nil : fix_dr_bullshit(GameObj.left_hand.name)
      end

      # Gets name of item in right hand
      #
      # @return [String,nil] Item name or nil if empty
      def right_hand
        GameObj.right_hand.name == 'Empty' ? nil : fix_dr_bullshit(GameObj.right_hand.name)
      end

      # Gets noun of item in left hand
      #
      # @return [String,nil] Item noun or nil if empty
      def left_hand_noun
        GameObj.left_hand == 'Empty' ? nil : GameObj.left_hand.noun
      end

      # Gets noun of item in right hand
      #
      # @return [String,nil] Item noun or nil if empty
      def right_hand_noun
        GameObj.right_hand == 'Empty' ? nil : GameObj.right_hand.noun
      end

      # Releases any active invisibility effects
      def release_invisibility
        get_data('spells')
          .spell_data
          .select { |_name, properties| properties['invisibility'] }
          .select { |name, _properties| DRSpells.active_spells.keys.include?(name) }
          .map { |_name, properties| properties['abbrev'] }
          .each { |abbrev| fput("release #{abbrev}") }

        # handle khri silence as it's not part of base-spells data, and method of ending it differs from spells
        bput('khri stop silence', 'You attempt to relax') if DRSpells.active_spells.keys.include?('Khri Silence')
      end

      # Checks current encumbrance level
      #
      # @param refresh [Boolean] Whether to refresh value
      # @return [Integer] Encumbrance level (0-4)
      def check_encumbrance(refresh = true)
        encumbrance = DRStats.encumbrance
        if refresh
          encumbrance_pattern = /(?:Encumbrance)\s:\s(?<encumbrance>.*)/
          case bput('encumbrance', encumbrance_pattern)
          when encumbrance_pattern
            encumbrance = Regexp.last_match[:encumbrance]
          end
        end
        $ENC_MAP[encumbrance]
      end

      # Attempts to retreat from combat
      #
      # @param ignored_npcs [Array<String>] NPCs to ignore
      # @return [Boolean] Whether retreat successful