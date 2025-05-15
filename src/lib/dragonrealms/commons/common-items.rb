# This module should be 'bottom-level' and only depend on common.
# Any modules that deal with items and <something> should be somewhere else

# Common item handling functionality for DragonRealms, providing methods for manipulating
# inventory items, containers, and equipment. This module serves as a base layer for
# item-related operations and should not depend on other modules except common.
module Lich
  module DragonRealms
    module DRCI
      module_function

      # List of valid trash receptacles for disposing items
      # @see https://github.com/elanthia-online/dr-scripts/wiki/Adding-new-trash-receptacles
      TRASH_STORAGE = %w[arms barrel basin basket bin birdbath bucket chamberpot gloop hole log puddle statue stump tangle tree turtle urn gelapod]

      # Success patterns for dropping trash items
      DROP_TRASH_SUCCESS_PATTERNS = [
        /^You drop/,
        /^You put/,
        /^You spread .* on the ground/,
        /smashing it to bits/,
        # The next message is when item crumbles when leaves your hand, like a moonblade.
        /^As you open your hand to release the/,
        /^You toss .* at the domesticated gelapod/,
        /^You feed .* a bit warily to the domesticated gelapod/
      ]

      # Failure patterns for dropping trash items
      DROP_TRASH_FAILURE_PATTERNS = [
        /^What were you referring to/,
        /^I could not find/,
        /^But you aren't holding that/,
        /^Perhaps you should be holding that first/,
        /^You're kidding, right/,
        /^You can't do that/,
        /^No littering/,
        /^Where do you want to put that/,
        /^You really shouldn't be loitering/,
        /^You don't seem to be able to move/,
        # You may get the next message if you've been cursed and unable to let go of items.
        # Find a Cleric to uncurse you.
        /^Oddly, when you attempt to stash it away safely/,
        /^You need something in your right hand/,
        /^You can't put that there/,
        /^The domesticated gelapod glances warily at/, # deeds
        /^You should empty it out, first./ # container with items
      ]

      # Messages that when trying to drop an item you're warned.
      # To continue you must retry the command.
      DROP_TRASH_RETRY_PATTERNS = [
        # You may get the next message if the item would be damaged upon dropping.
        /^If you still wish to drop it/,
        /would damage it/,
        # You may get the next messages when an outdated item is updated upon use.
        # "Something appears different about the <item>, perhaps try doing that again."
        # Example: https://elanthipedia.play.net/Item:Leather_lotion
        /^Something appears different about/,
        /perhaps try doing that again/
      ]

      # Success patterns for worn trashcan verbs
      WORN_TRASHCAN_VERB_PATTERNS = [
        /^You drum your fingers/,
        /^You pull a lever/,
        /^You poke your finger around/
      ]

      # Success patterns for getting items
      GET_ITEM_SUCCESS_PATTERNS = [
        /you draw (?!\w+'s wounds)/i,
        /^You get/,
        /^You pick/,
        /^You pluck/,
        /^You slip/,
        /^You deftly remove/,
        /^You are already holding/,
        /^You fade in for a moment as you/,
        /^You carefully lift/,
        /^You carefully remove .* from the bundle/
      ]

      # Failure patterns for getting items
      GET_ITEM_FAILURE_PATTERNS = [
        /^A magical force keeps you from grasping/,
        /^You need a free hand/,
        /^You can't pick that up with your hand that damaged/,
        /^Your (left|right) hand is too injured/,
        /^You just can't/,
        /^You stop as you realize the .* is not yours/,
        /^You can't reach that from here/, # on a mount like a flying carpet
        /^You don't seem to be able to move/,
        /^You should untie/,
        /^You can't do that/,
        /^Get what/,
        /^I could not/,
        /^What were you/,
        /already in your inventory/, # wearing it
        /needs to be tended to be removed/, # ammo lodged in you
        /push you over the item limit/, # you're at item capacity
        /rapidly decays away/, # item disappears when try to get it
        /cracks and rots away/, # item disappears when try to get it
        /^You should stop practicing your Athletics skill before you do that/
      ]

      # Success patterns for wearing items
      WEAR_ITEM_SUCCESS_PATTERNS = [
        /^You put/,
        /^You pull/,
        /^You sling/,
        /^You attach/,
        /^You strap/,
        /^You slide/,
        /^You spin/,
        /^You slip/,
        /^You place/,
        /^You hang/,
        /^You tug/,
        /^You struggle/,
        /^You squeeze/,
        /^You manage/,
        /^You gently place/,
        /^You toss one strap/,
        /^You carefully loop/,
        /^You work your way into/,
        /^You are already wearing/,
        /^Gritting your teeth, you grip/,
        /put it on/, # weird clerical collar thing, trying to make it a bit generic
        /slide effortlessly onto your/,
        /^You carefully arrange/,
        /^A brisk chill rushes through you as you wear/, # some hiro bearskin gloves interlaced with strips of ice-veined leather
        /^You drape/,
        /You lean over and slip your feet into the boots./, # a pair of weathered barkcloth boots lined in flannel,
        /^You reach down and step into/ # pair of enaada boots clasped by asharsh'dai
      ]

      # Failure patterns for wearing items
      WEAR_ITEM_FAILURE_PATTERNS = [
        /^You can't wear/,
        /^You (need to|should) unload/,
        /close the fan/,
        /^You don't seem to be able to move/,
        /^Wear what/,
        /^I could not/,
        /^What were you/
      ]

      # Success patterns for tying items
      TIE_ITEM_SUCCESS_PATTERNS = [
        /^You .* tie/,
        /^You attach/
      ]

      # Failure patterns for tying items
      TIE_ITEM_FAILURE_PATTERNS = [
        /^You don't seem to be able to move/,
        /^There's no more free ties/,
        /^You must be holding/,
        /doesn't seem to fit/,
        /^You are a little too busy/,
        /^Your wounds hinder your ability to do that/,
        /^Tie what/
      ]

      # Success patterns for untying items
      UNTIE_ITEM_SUCCESS_PATTERNS = [
        /^You remove/,
        /You untie/i
      ]

      # Failure patterns for untying items
      UNTIE_ITEM_FAILURE_PATTERNS = [
        /^You don't seem to be able to move/,
        /^You fumble with the ties/,
        /^Untie what/,
        /^What were you referring/
      ]

      # Success patterns for removing items
      REMOVE_ITEM_SUCCESS_PATTERNS = [
        /^Dropping your shoulder/,
        /^The .* slide/,
        /^Without any effort/,
        /^You .* slide/,
        /^You detach/,
        /^You loosen/,
        /^You pull/,
        /^You.*remove/,
        /^You slide/,
        /^You sling/,
        /^You slip/,
        /^You struggle/,
        /^You take/,
        /you tug/i,
        /^You untie/,
        /as you remove/,
        /slide themselves off of your/,
        /you manage to loosen/,
        /you unlace/,
        /^You slam the heels/
      ]

      # Failure patterns for removing items
      REMOVE_ITEM_FAILURE_PATTERNS = [
        /^You need a free hand/,
        /^You aren't wearing/,
        /^You don't seem to be able to move/,
        /^Remove what/,
        /^I could not/,
        /^What were you/
      ]

      # Success patterns for putting away items
      PUT_AWAY_ITEM_SUCCESS_PATTERNS = [
        /^You put your .* in/,
        /^You hold out/,
        /^You tuck/,
        /^You open your pouch and put/,
        /^You guide your/i, # puppy storage
        /^You hang/, # frog belt
        /^You nudge your/i, # monkey storage
        # The next message is when item crumbles when stowed, like a moonblade.
        /^As you open your hand to release the/,
        # You're a thief and you binned a stolen item.
        /nods toward you as your .* falls into the .* bin/,
        /^You add/,
        /^You rearrange/,
        /^You combine the stacks/,
        /^You secure/,
        # The following are success messages for putting an item in a container OFF your person.
        /^You drop/i,
        /^You set/i,
        /You put/i,
        /^You carefully fit .* into your bundle/,
        /^You slip/,
        /^You easily strap/,
        /^You gently set/,
        /^You toss .* into/ # You toss the alcohol into the bowl and mix it in thoroughly
      ]

      # Failure patterns for putting away items
      PUT_AWAY_ITEM_FAILURE_PATTERNS = [
        /^Stow what/,
        /^I can't find your container for stowing things in/,
        /^Please rephrase that command/,
        /^What were you referring to/,
        /^I could not find what you were referring to/,
        /^There isn't any more room in/,
        /^There's no room/,
        /^(The|That).* too heavy to go in there/,
        /^You (need to|should) unload/,
        /^You can't do that/,
        /^You just can't get/,
        /^You can't put items/,
        /^You can only take items out/,
        /^You don't seem to be able to move/,
        /^Perhaps you should be holding that first/,
        /^Containers can't be placed in/,
        /^The .* is not designed to carry anything/,
        /^You can't put that.*there/,
        /^Weirdly, you can't manage .* to fit/,
        /^\[Containers can't be placed in/,
        /even after stuffing it/,
        /is too .* to (fit|hold)/,
        /no matter how you arrange it/,
        /close the fan/,
        /to fit in the/,
        /doesn't seem to want to leave you/, # trying to put a pet in a home within a container
        # You may get the next message if you've been cursed and unable to let go of items.
        # Find a Cleric to uncurse you.
        /Oddly, when you attempt to stash it away safely/,
        /completely full/,
        /That doesn't belong in there!/,
        /exerts a steady force preventing/
      ]

      # Messages that when trying to put away an item you're warned.
      # To continue you must retry the command.
      PUT_AWAY_ITEM_RETRY_PATTERNS = [
        # You may get the next messages when an outdated item is updated upon use.
        # "Something appears different about the <item>, perhaps try doing that again."
        # Example: https://elanthipedia.play.net/Item:Leather_lotion
        /Something appears different about/,
        /perhaps try doing that again/
      ]

      # Combined success patterns for stowing items
      STOW_ITEM_SUCCESS_PATTERNS = [
        *GET_ITEM_SUCCESS_PATTERNS,
        *PUT_AWAY_ITEM_SUCCESS_PATTERNS
      ]

      # Combined failure patterns for stowing items
      STOW_ITEM_FAILURE_PATTERNS = [
        *GET_ITEM_FAILURE_PATTERNS,
        *PUT_AWAY_ITEM_FAILURE_PATTERNS,
      ]

      # Combined retry patterns for stowing items
      STOW_ITEM_RETRY_PATTERNS = [
        *PUT_AWAY_ITEM_RETRY_PATTERNS
      ]

      # Success patterns for rummaging containers
      RUMMAGE_SUCCESS_PATTERNS = [
        /^You rummage through .* and see (.*)\./,
        /^In the .* you see (.*)\./,
        /there is nothing/i
      ]

      # Failure patterns for rummaging containers
      RUMMAGE_FAILURE_PATTERNS = [
        /^You don't seem to be able to move/,
        /^I could not find/,
        /^I don't know what you are referring to/,
        /^What were you referring to/
      ]

      # Success patterns for tapping items
      TAP_SUCCESS_PATTERNS = [
        /^You tap\s(?!into).*/, # The `.*` is needed to capture entire phrase. Methods parse it to know if an item is worn, stowed, etc.
        /^You (thump|drum) your finger/, # You tapped an item with fancy verbiage, ohh la la!
        /^As you tap/, # As you tap a large ice-veined leather and flamewood surveyor's case
        /^The orb is delicate/, # You tapped a favor orb
        /^You .* on the shoulder/, # You tapped someone
        /^You suddenly forget what you were doing/ # "tap my tessera" messaging when hands are full
      ]

      # Failure patterns for tapping items
      TAP_FAILURE_PATTERNS = [
        /^You don't seem to be able to move/,
        /^I could not find/,
        /^I don't know what you are referring to/,
        /^What were you referring to/
      ]

      # Success patterns for opening containers
      OPEN_CONTAINER_SUCCESS_PATTERNS = [
        /^You open/,
        /^You slowly open/,
        /^The .* opens/,
        /^You unbutton/,
        /(It's|is) already open/,
        /^You spread your arms, carefully holding your bag well away from your body/
      ]

      # Failure patterns for opening containers
      OPEN_CONTAINER_FAILURE_PATTERNS = [
        /^Please rephrase that command/,
        /^What were you referring to/,
        /^I could not find what you were referring to/,
        /^You don't want to ruin your spell just for that do you/,
        /^It would be a shame to disturb the silence of this place for that/,
        /^This is probably not the time nor place for that/,
        /^You don't seem to be able to move/,
        /^There is no way to do that/,
        /^You can't do that/,
        /^Open what/
      ]

      # Success patterns for closing containers
      CLOSE_CONTAINER_SUCCESS_PATTERNS = [
        /^You close/,
        /^You quickly close/,
        /^You pull/,
        /is already closed/
      ]

      # Failure patterns for closing containers
      CLOSE_CONTAINER_FAILURE_PATTERNS = [
        /^Please rephrase that command/,
        /^What were you referring to/,
        /^I could not find what you were referring to/,
        /^You don't want to ruin your spell just for that do you/,
        /^It would be a shame to disturb the silence of this place for that/,
        /^This is probably not the time nor place for that/,
        /^You don't seem to be able to move/,
        /^There is no way to do that/,
        /^You can't do that/
      ]

      # Patterns indicating a container is closed
      CONTAINER_IS_CLOSED_PATTERNS = [
        /^But that's closed/,
        /^That is closed/,
        /^While it's closed/
      ]

      # Success patterns for lowering items
      LOWER_SUCCESS_PATTERNS = [
        /^You lower/,
        # The next message is when item crumbles when leaves your hand, like a moonblade.
        /^As you open your hand to release the/
      ]

      # Failure patterns for lowering items
      LOWER_FAILURE_PATTERNS = [
        /^You don't seem to be able to move/,
        /^But you aren't holding anything/,
        /^Please rephrase that command/,
        /^What were you referring to/,
        /^I could not find what you were referring to/
      ]

      # Success patterns for lifting items
      LIFT_SUCCESS_PATTERNS = [
        /^You pick up/
      ]

      # Failure patterns for lifting items
      LIFT_FAILURE_PATTERNS = [
        /^There are no items lying at your feet/,
        /^What did you want to try and lift/,
        /can't quite lift it/,
        /^You are not strong enough to pick that up/
      ]

      # Success patterns for giving items
      GIVE_ITEM_SUCCESS_PATTERNS = [
        /has accepted your offer/,
        /your ticket and are handed back/,
        /Please don't lose this ticket!/,
        /^You hand .* gives you back a repair ticket/,
        /^You hand .* your ticket and are handed back/
      ]

      # Failure patterns for giving items
      GIVE_ITEM_FAILURE_PATTERNS = [
        /I don't repair those here/,
        /There isn't a scratch on that/,
        /give me a few more moments/,
        /I will not repair something that isn't broken/,
        /I can't fix those/,
        /has declined the offer/,
        /^Your offer to .* has expired/,
        /^You may only have one outstanding offer at a time/,
        /^What is it you're trying to give/,
        /Lucky for you!  That isn't damaged!/
      ]

      # Disposes of an item by putting it in a trash receptacle or dropping it
      #
      # @param item [String] the item to dispose of
      # @param worn_trashcan [String, nil] optional worn container to use as trash
      # @param worn_trashcan_verb [String, nil] optional verb to use with worn container
      # @return [Boolean] true if item was disposed, false otherwise
      # @example
      #   dispose_trash('stick')
      #   dispose_trash('paper', 'wastebasket', 'push')
      def dispose_trash(item, worn_trashcan = nil, worn_trashcan_verb = nil)
        return unless item
        return unless DRCI.get_item_if_not_held?(item)

        if worn_trashcan
          case DRC.bput("put my #{item} in my #{worn_trashcan}", DROP_TRASH_RETRY_PATTERNS, DROP_TRASH_SUCCESS_PATTERNS, DROP_TRASH_FAILURE_PATTERNS, /^Perhaps you should be holding that first/)
          when /^Perhaps you should be holding that first/
            return (DRCI.get_item?(item) && DRCI.dispose_trash(item, worn_trashcan, worn_trashcan_verb))
          when *DROP_TRASH_RETRY_PATTERNS
            return DRCI.dispose_trash(item, worn_trashcan, worn_trashcan_verb)
          when *DROP_TRASH_SUCCESS_PATTERNS
            if worn_trashcan_verb
              DRC.bput("#{worn_trashcan_verb} my #{worn_trashcan}", *WORN_TRASHCAN_VERB_PATTERNS)
              DRC.bput("#{worn_trashcan_verb} my #{worn_trashcan}", *WORN_TRASHCAN_VERB_PATTERNS)
            end
            return true
          end
        end

        trashcans = DRRoom.room_objs
                          .reject { |obj| obj =~ /azure \w+ tree/ }
                          .map { |long_name| DRC.get_noun(long_name) }
                          .select { |obj| TRASH_STORAGE.include?(obj) }

        trashcans.each do |trashcan|
          if trashcan == 'gloop'
            trashcan = 'bucket' if DRRoom.room_objs.include?('bucket of viscous gloop')
            trashcan = 'cauldron' if DRRoom.room_objs.include?('small bubbling cauldron of viscous gloop')
          elsif trashcan == 'bucket'
            trashcan = 'sturdy bucket' if DRRoom.room_objs.include?('sturdy bucket')
          elsif trashcan == 'basket'
            trashcan = 'waste basket' if DRRoom.room_objs.include?('waste basket')
          elsif trashcan == 'bin'
            trashcan = 'waste bin' if DRRoom.room_objs.include?('waste bin')
            trashcan = 'small bin' if DRRoom.room_objs.include?('small bin concealed with some nearby brush')
          elsif trashcan == 'arms'
            trashcan = 'statue'
          elsif trashcan == 'birdbath'
            trashcan = 'alabaster birdbath'
          elsif trashcan == 'turtle'
            trashcan = 'stone turtle'
          elsif trashcan == 'tree'
            trashcan = 'hollow' if DRRoom.room_objs.include?('dead tree with a darkened hollow near its base')
          elsif trashcan == 'basin'
            trashcan = 'stone basin' if DRRoom.room_objs.include?('hollow stone basin')
          elsif trashcan == 'tangle'
            trashcan = 'dark gap' if DRRoom.room_objs.include?('tangle of thick roots forming a dark gap')
          elsif XMLData.room_title == '[[A Junk Yard]]'
            trashcan = 'bin'
          elsif trashcan == 'gelapod'
            trash_command = "feed my #{item} to gelapod"
          end

          trash_command = "put my #{item} in #{trashcan}" unless trashcan == 'gelapod'

          case DRC.bput(trash_command, DROP_TRASH_SUCCESS_PATTERNS, DROP_TRASH_FAILURE_PATTERNS, DROP_TRASH_RETRY_PATTERNS, /^Perhaps you should be holding that first/)
          when /^Perhaps you should be holding that first/
            return (DRCI.get_item?(item) && DRCI.dispose_trash(item))
          when *DROP_TRASH_RETRY_PATTERNS
            # If still didn't dispose of trash after retry
            # then don't return yet, will try to drop it later.
            return true if dispose_trash(item)
          when *DROP_TRASH_SUCCESS_PATTERNS
            return true
          end
        end

        # No trash bins or not able to put item in a bin, just drop it.
        case DRC.bput("drop my #{item}", DROP_TRASH_SUCCESS_PATTERNS, DROP_TRASH_FAILURE_PATTERNS, DROP_TRASH_RETRY_PATTERNS, /^Perhaps you should be holding that first/, /^But you aren't holding that/)
        when /^Perhaps you should be holding that first/, /^But you aren't holding that/
          return (DRCI.get_item?(item) && DRCI.dispose_trash(item))
        when *DROP_TRASH_RETRY_PATTERNS
          return dispose_trash(item)
        when *DROP_TRASH_SUCCESS_PATTERNS
          return true
        else
          return false
        end
      end

      # Searches inventory for an item
      #
      # @param item [String] the item to search for
      # @return [Boolean] true if item found, false otherwise
      # @example
      #   search?('sword')
      def search?(item)
        /Your .* is in/ =~ DRC.bput("inv search #{item}", /^You can't seem to find anything/, /Your .* is in/)
      end

      # Checks if an item is being worn
      #
      # @param item [String] the item to check
      # @return [Boolean] true if item is worn, false otherwise
      # @example
      #   wearing?('cloak')
      def wearing?(item)
        tap(item) =~ /wearing/
      end

      # Checks if an item is inside a container
      #
      # @param item [String] the item to check
      # @param container [String, nil] the container to check in
      # @return [Boolean] true if item is in container, false otherwise
      # @example
      #   inside?('gem', 'backpack')
      def inside?(item, container = nil)
        tap(item, container) =~ /inside/
      end

      # Checks if an item exists in inventory
      #
      # @param item [String] the item to check
      # @param container [String, nil] optional container to check in
      # @return [Boolean] true if item exists, false otherwise
      # @example
      #   exists?('sword')
      #   exists?('gem', 'backpack')
      def exists?(item, container = nil)
        case tap(item, container)
        when *TAP_SUCCESS_PATTERNS
          true
        else
          false
        end
      end

      # Taps an item to get information about it
      #
      # @param item [String] the item to tap
      # @param container [String, nil] optional container the item is in
      # @return [String, nil] the tap message or nil if failed
      # @example
      #   tap('sword')
      #   tap('gem', 'backpack')
      def tap(item, container = nil)
        return nil unless item

        from = container
        from = "from #{container}" if container && !(container =~ /^(in|on|under|behind|from) /i)
        DRC.bput("tap my #{item} #{from}", *TAP_SUCCESS_PATTERNS, *TAP_FAILURE_PATTERNS)
      end

      # Checks if an item is in hands
      #
      # @param item [String] the item to check
      # @return [Boolean] true if item is in either hand
      # @example
      #   in_hands?('sword')
      def in_hands?(item)
        in_hand?(item, 'either')
      end

      # Checks if an item is in the left hand
      #
      # @param item [String] the item to check
      # @return [Boolean] true if item is in left hand
      # @example
      #   in_left_hand?('sword')
      def in_left_hand?(item)
        in_hand?(item, 'left')
      end

      # Checks if an item is in the right hand
      #
      # @param item [String] the item to check
      # @return [Boolean] true if item is in right hand
      # @example
      #   in_right_hand?('sword')
      def in_right_hand?(item)
        in_hand?(item, 'right')
      end

      # Checks if an item is in a specific hand
      #
      # @param item [String] the item to check
      # @param which_hand [String] which hand to check ('left', 'right', 'either', 'both')
      # @return [Boolean] true if item is in specified hand(s)
      # @example
      #   in_hand?('sword', 'right')
      def in_hand?(item, which_hand = 'either')
        return false unless item

        item = DRC::Item.from_text(item) if item.is_a?(String)
        case which_hand.downcase
        when 'left'
          DRC.left_hand =~ item.short_regex
        when 'right'
          DRC.right_hand =~ item.short_regex
        when 'either'
          in_left_hand?(item) || in_right_hand?(item)
        when 'both'
          in_left_hand?(item) && in_right_hand?(item)
        else
          DRC.message("Unknown hand: #{which_hand}. Valid options are: left, right, either, both")
          false
        end
      end

      # Checks if an item exists by looking at it
      #
      # @param item [String] the item to check
      # @param container [String] the container to look in
      # @return [Boolean] true if item exists, false otherwise
      # @example
      #   have_item_by_look?('sword', 'backpack')
      def have_item_by_look?(item, container)
        return false unless item

        item = item.delete_prefix('my ')
        preposition = 'in my' if container && !(container =~ /^((in|on|under|behind|from) )?my /i)

        case DRC.bput("look at my #{item} #{preposition} #{container}", item, /^You see nothing unusual/, /^I could not find/, /^What were you referring to/)
        when /You see nothing unusual/, item
          true
        else
          false
        end
      end

      # Counts parts remaining in a stackable item
      #
      # @param item [String] the stackable item to count
      # @return [Integer] number of parts remaining
      # @example
      #   count_item_parts('arrows')
      def count_item_parts(item)
        match_messages = [
          /and see there (?:is|are) (.+) left\./,
          /There (?:is|are) (?:only )?(.+) parts? left/,
          /There's (?:only )?(.+) parts? left/,
          /The (?:.+) has (.+) uses remaining./,
          /There are enough left to create (.+) more/,
          /You count out (.+) pieces? of material there/,
          /There (?:is|are) (.+) scrolls? left for use with crafting/
        ]
        count = 0
        $ORDINALS.each do |ordinal|
          case DRC.bput("count my #{ordinal} #{item}",
                        'I could not find what you were referring to.',
                        'tell you much of anything.',
                        *match_messages)
          when 'I could not find what you were referring to.'
            break
          when 'tell you much of anything.'
            echo "ERROR: count_item_parts called on non-stackable item: #{item}"
            count = count_items(item)
            break
          when *match_messages
            countval = Regexp.last_match(1).tr('-', ' ')
            if countval.match?(/\A\d+\z/)
              count += Integer(countval)
            else
              count += D