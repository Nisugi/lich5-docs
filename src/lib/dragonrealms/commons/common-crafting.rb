# Module for DragonRealms crafting helper methods
#
# Contains utility methods for managing crafting activities in DragonRealms including
# finding crafting locations, managing tools and materials, and handling recipes.
module Lich
  module DragonRealms
    module DRCC
      module_function

      # Checks if a crucible is empty and cleans it if needed
      #
      # @return [Boolean] true if crucible is empty, false if crucible cannot be found or accessed
      def empty_crucible?
        case result = DRC.bput('look in cruc',
                               '^I could not find',
                               '^There is nothing in there',
                               '^In the .* crucible you see (.*)\.')
        when /There is nothing in there/i
          true
        when /I could not find/
          false
        when /crucible you see some molten/
          fput('tilt crucible')
          fput('tilt crucible')
          return DRCC.empty_crucible?
        when /crucible you see/
          clutter = result
                    .match(/In the .* you see (?:some|an|a) (?<items>.*)\./)[:items]
                    .split(/(?:,|and) (?:some|an|a)/)
                    .map(&:strip)
          clutter.each { |junk|
            junk = DRC.get_noun(junk)
            DRCI.get_item_unsafe(junk, 'crucible')
            DRCI.dispose_trash(junk)
          }
          return DRCC.empty_crucible?
        else
          false
        end
      end

      # Locates an empty crucible in the specified hometown
      #
      # @param hometown [String] the name of the town to search in
      # @return [void]
      def find_empty_crucible(hometown)
        return if DRC.bput('tap crucible', 'I could not', /You tap.*crucible/) =~ /You tap.*crucible/ && (DRRoom.pcs - DRRoom.group_members).empty? && empty_crucible?

        crucibles = get_data('crafting')['blacksmithing'][hometown]['crucibles']
        idle_room = get_data('crafting')['blacksmithing'][hometown]['idle-room']
        DRCT.find_sorted_empty_room(crucibles, idle_room, proc { (DRRoom.pcs - DRRoom.group_members).empty? && empty_crucible? })
        DRCC.clean_anvil?
      end

      # Checks if an anvil is clean and cleans it if needed
      #
      # @return [Boolean] true if anvil is clean, false if anvil cannot be found or accessed
      def clean_anvil?
        case result = DRC.bput('look on anvil', '^I could not find', 'surface looks clean and ready', "anvil you see (.*)\.")
        when /surface looks clean and ready/i
          true
        when /I could not find/
          false
        when /anvil you see/
          /anvil you see (.*)\./ =~ result
          clutter = Regexp.last_match(1).split.last
          case DRC.bput('clean anvil', 'You drag the', 'remove them yourself')
          when /drag/
            fput('clean anvil')
            pause
            waitrt?
          else
            case DRC.bput("get #{clutter} from anvil", 'You get', 'is not yours')
            when 'is not yours'
              fput('clean anvil')
              fput('clean anvil')
            when 'You get'
              DRC.bput("put #{clutter} in bucket", 'You drop')
            else
              return false
            end
          end
          true
        else
          false
        end
      end

      # Finds a spinning wheel in the specified hometown
      #
      # @param hometown [String] the name of the town to search in
      # @return [void]
      def find_wheel(hometown)
        wheels = get_data('crafting')['tailoring'][hometown]['spinning-rooms']
        idle_room = get_data('crafting')['tailoring'][hometown]['idle-room']
        DRCT.find_sorted_empty_room(wheels, idle_room)
      end

      # Locates an empty anvil in the specified hometown
      #
      # @param hometown [String] the name of the town to search in
      # @return [void]
      def find_anvil(hometown)
        return if DRC.bput('tap anvil', 'I could not', /You tap.*anvil/) =~ /You tap.*anvil/ && (DRRoom.pcs - DRRoom.group_members).empty? && clean_anvil?

        anvils = get_data('crafting')['blacksmithing'][hometown]['anvils']
        idle_room = get_data('crafting')['blacksmithing'][hometown]['idle-room']
        DRCT.find_sorted_empty_room(anvils, idle_room, proc { (DRRoom.pcs - DRRoom.group_members).empty? && clean_anvil? })
        DRCC.empty_crucible?
      end

      # Finds a grindstone in the specified hometown
      #
      # @param hometown [String] the name of the town to search in
      # @return [void]
      def find_grindstone(hometown)
        return unless DRC.bput('tap grindstone', 'I could not', 'You tap.*grindstone') == 'I could not'

        grindstones = get_data('crafting')['blacksmithing'][hometown]['grindstones']
        idle_room = get_data('crafting')['blacksmithing'][hometown]['idle-room']
        DRCT.find_sorted_empty_room(grindstones, idle_room)
      end

      # Finds a sewing room in the specified hometown
      #
      # @param hometown [String] the name of the town to search in
      # @param override [Integer, nil] optional room number override
      # @return [void]
      def find_sewing_room(hometown, override = nil)
        if override
          DRCT.walk_to(override)
        else
          sewingrooms = get_data('crafting')['tailoring'][hometown]['sewing-rooms']
          idle_room = get_data('crafting')['tailoring'][hometown]['idle-room']
          DRCT.find_sorted_empty_room(sewingrooms, idle_room)
        end
      end

      # Finds a loom room in the specified hometown
      #
      # @param hometown [String] the name of the town to search in
      # @param override [Integer, nil] optional room number override
      # @return [void]
      def find_loom_room(hometown, override = nil)
        if override
          DRCT.walk_to(override)
        else
          loom_rooms = get_data('crafting')['tailoring'][hometown]['loom-rooms']
          idle_room = get_data('crafting')['tailoring'][hometown]['idle-room']
          DRCT.find_sorted_empty_room(loom_rooms, idle_room)
        end
      end

      # Finds a shaping room in the specified hometown
      #
      # @param hometown [String] the name of the town to search in
      # @param override [Integer, nil] optional room number override
      # @return [void]
      def find_shaping_room(hometown, override = nil)
        if override
          DRCT.walk_to(override)
        else
          shapingrooms = get_data('crafting')['shaping'][hometown]['shaping-rooms']
          idle_room = get_data('crafting')['shaping'][hometown]['idle-room']
          DRCT.find_sorted_empty_room(shapingrooms, idle_room)
        end
      end

      # Finds a press grinder room in the specified hometown
      #
      # @param hometown [String] the name of the town to search in
      # @return [void]
      def find_press_grinder_room(hometown)
        return unless DRC.bput('tap grinder', 'I could not', 'You tap.*grinder') == 'I could not'

        pressgrinderrooms = get_data('crafting')['remedies'][hometown]['press-grinder-rooms']
        DRCT.walk_to(pressgrinderrooms[0])
      end

      # Finds an enchanting room in the specified hometown
      #
      # @param hometown [String] the name of the town to search in
      # @param override [Integer, nil] optional room number override
      # @return [void]
      def find_enchanting_room(hometown, override = nil)
        if override
          DRCT.walk_to(override)
        else
          enchanting_rooms = get_data('crafting')['artificing'][hometown]['brazier-rooms']
          idle_room = get_data('crafting')['artificing'][hometown]['idle-room']
          DRCT.find_sorted_empty_room(enchanting_rooms, idle_room, proc { (DRRoom.pcs - DRRoom.group_members).empty? && clean_brazier? })
        end
      end

      # Looks up a recipe by name in the recipe list
      #
      # @param recipes [Array<Hash>] array of recipe hashes
      # @param item_name [String] name of item to find recipe for
      # @return [Hash, nil] matching recipe hash or nil if not found
      def recipe_lookup(recipes, item_name)
        match_names = recipes.map { |x| x['name'] }.select { |x| x =~ /#{item_name}/i }
        case match_names.length
        when 0
          echo("No recipe in base-recipes.yaml matches #{item_name}")
          nil
        when 1
          recipes.find { |x| x['name'] =~ /#{item_name}/i }
        else
          exact_matches = recipes.map { |x| x['name'] }.select { |x| x == item_name }

          if exact_matches.length == 1
            return recipes.find { |x| x['name'] == item_name }
          end

          DRC.message("Using the full name of the item you wish to craft will avoid this in the future (e.g. 'a metal pike' vs 'metal pike')")
          echo("Please select desired recipe #{$clean_lich_char}send #")
          match_names.each_with_index { |x, i| respond "    #{i + 1}: #{x}" }
          line = get until line.strip =~ /^([0-9]+)$/
          item_name = match_names[Regexp.last_match(1).to_i - 1]
          recipes.find { |x| x['name'] =~ /#{item_name}/i }
        end
      end

      # Finds a recipe in a crafting book
      #
      # @param chapter [Integer] chapter number to look in
      # @param match_string [String] string to match recipe name
      # @param book [String] name of book to search
      # @return [String] page number containing the recipe
      def find_recipe(chapter, match_string, book = 'book')
        case DRC.bput("turn my #{book} to chapter #{chapter}", 'You turn', 'You are too distracted to be doing that right now', 'The .* is already turned')
        when 'You are too distracted to be doing that right now'
          echo '***CANNOT TURN BOOK, ASSUMING I AM ENGAGED IN COMBAT***'
          fput('look')
          fput('exit')
        end

        recipe = DRC.bput("read my #{book}", "Page \\d+:\\s(?:some|a|an)?\\s*#{match_string}").split('Page').find { |x| x =~ /#{match_string}/i }
        recipe =~ /(\d+):/
        Regexp.last_match(1)
      end

      # Enhanced version of find_recipe that also handles disciplines
      #
      # @param chapter [Integer] chapter number
      # @param match_string [String] string to match recipe name
      # @param book [String] name of book to search
      # @param discipline [String, nil] optional crafting discipline
      # @return [void]
      def find_recipe2(chapter, match_string, book = 'book', discipline = nil)
        DRC.bput("turn my #{book} to discipline #{discipline}", /^You turn the #{book} to the section on/) unless discipline.nil?
        case DRC.bput("turn my #{book} to chapter #{chapter}", /^You turn your #{book} to chapter/, /^The #{book} is already turned to chapter/, /^You are too distracted to be doing that right now./)
        when /^You are too distracted to be doing that right now./
          echo '***CANNOT TURN BOOK, ASSUMING I AM ENGAGED IN COMBAT***'
          fput('look')
          fput('exit')
        end

        recipe = DRC.bput("read my #{book}", "Page \\d+:\\s(?:some|a|an)?\\s*#{match_string}").split('Page').find { |x| x =~ /#{match_string}/i }
        recipe =~ /(\d+):/
        page = Regexp.last_match(1)
        DRC.bput("turn my #{book} to page #{page}", /^You turn your #{book} to page/, /^You are already on page/)
        DRC.bput("study my #{book}", /^Roundtime/)
      end

      # Gets a crafting item from storage
      #
      # @param name [String] name of item to get
      # @param bag [String] container to get item from
      # @param bag_items [Array<String>] list of items in bag
      # @param belt [Hash] belt information hash
      # @param skip_exit [Boolean] whether to exit on failure
      # @return [void]
      def get_crafting_item(name, bag, bag_items, belt, skip_exit = false)
        waitrt?
        if belt && belt['items'].find { |item| /\b#{name}/i =~ item || /\b#{item}/i =~ name }
          case DRC.bput("untie my #{name} from my #{belt['name']}", /^You (remove|untie)/, /^You are already/, /^Untie what/, /^Your wounds hinder your ability to do that/)
          when /You (remove|untie)/, /You are already/
            return
          when /Your wounds hinder your ability to do that/
            craft_room = Room.current.id
            DRC.wait_for_script_to_complete('safe-room', ['force'])
            DRCT.walk_to(craft_room)
            return get_crafting_item(name, bag, bag_items, belt)
          end
        end
        command = "get my #{name}"
        command += " from my #{bag}" if bag_items && bag_items.include?(name)
        case DRC.bput(command, /^You get/, /^You are already/, /^What do you/, /^What were you/, /^You pick up/, /can't quite lift it/, /^You should untie/)
        when 'What do you', 'What were you'
          pause 2
          return if DRCI.in_hands?(name)

          DRC.beep
          echo("You seem to be missing: #{name}")
          exit unless skip_exit
        when "can't quite lift it"
          get_crafting_item(name, bag, bag_items, belt)
        when 'You should untie'
          case DRC.bput("untie my #{name}", /^You (remove|untie)/, /^Untie what/, /^Your wounds hinder your ability to do that/)
          when /You (remove|untie)/
            return
          when /Your wounds hinder your ability to do that/
            craft_room = Room.current.id
            DRC.wait_for_script_to_complete('safe-room', ['force'])
            DRCT.walk_to(craft_room)
            return get_crafting_item(name, bag, bag_items, belt)
          end
        end
      end

      # Stows a crafting item
      #
      # @param name [String] name of item to stow
      # @param bag [String] container to stow in
      # @param belt [Hash] belt information hash
      # @return [Boolean] true if stowed successfully
      def stow_crafting_item(name, bag, belt)
        return unless name

        waitrt?
        if belt && belt['items'].find { |item| /\b#{name}/i =~ item || /\b#{item}/i =~ name }
          case DRC.bput("tie my #{name} to my #{belt['name']}", 'you attach', 'Your wounds hinder')
          when 'Your wounds hinder'
            craft_room = Room.current.id
            DRC.wait_for_script_to_complete('safe-room', ['force'])
            DRCT.walk_to(craft_room)
            return stow_crafting_item(name, bag, belt)
          end
        else
          case DRC.bput("put my #{name} in my #{bag}", 'You tuck', 'You put your', 'What were you referring to', 'is too \w+ to fit', 'Weirdly, you can\'t manage', 'There\'s no room', 'You can\'t put that there', 'You combine')
          when /is too \w+ to fit/, 'Weirdly, you can\'t manage', 'There\'s no room'
            fput("stow my #{name}")
          when 'You can\'t put that there'
            fput("put my #{name} in my other #{bag}")
            return false
          end
        end
        true
      end

      # Calculates the cost of crafting items
      #
      # @param recipe [Hash] recipe information
      # @param hometown [String] town name for currency conversion
      # @param parts [Array<String>] required parts
      # @param quantity [Integer] number of items to craft
      # @param material [Hash] material information
      # @return [Integer] total cost in local currency
      def crafting_cost(recipe, hometown, parts, quantity, material)
        # To use this method, you'll need to pass:
        # recipe => This is a hash drawn directly from base-recipes eg {name: 'a metal ring cap', noun: 'cap', volume: 8, type: 'armorsmithing',etc}
        #     This is fetched via get_data('recipes').crafting_recipes('name')[<name of recipe>]
        # hometown => Just a string eg "Crossing"
        # parts => This is an array containing(if any) a list of parts required. Where base-recipes doesn't do this, you will need to format this.
        # quantity => an integer representing how many of each finished craft you intend to make. You can call this once per item, or once for all items.
        # material => This needs to be a hash drawn directly from base-crafting eg {stock-volume: 5, stock-number: 11, stock-name: 'bronze', stock-value: 562}
        #     This is fetched via get_data('crafting')['stock'][<name of material>]
        #     nil or false if not using stock materials

        currency = DRCM.town_currency(hometown)
        data = get_data('crafting')['stock'] # fetch parts data

        if material && ["alabaster", "granite", "marble"].any? { |x| material['stock-name'] == x } # stone isn't stackable, so just calculate stock*quantity
          total += material['stock-value'] * quantity
        elsif material # neither alchemy nor artificing have ONE stock material, they take various materials and combine them, so those are handled by parts below
          stock_to_order = ((recipe['volume'] / material['stock-volume'].to_f) * quantity).ceil
          total += (stock_to_order * material['stock-value'])
        end

        if parts
          parts_cannot_purchase = ['sufil', 'blue flower', 'muljin', 'belradi', 'dioica', 'hulnik', 'aloe', 'eghmok', 'lujeakave', 'yelith', 'cebi', 'blocil', 'hulij', 'nuloe', 'hisan', 'gem', 'pebble', 'ring', 'gwethdesuan', 'brazier', 'burin', 'any', 'ingot', 'mechanism']
          parts.reject! { |part| parts_cannot_purchase.include?(part) } # excludes things you cannot purchase, so won't error if you've got these.
          parts.each { |part| total += data[part]['stock-value'] * quantity } # adds the cost of each purchasable part to the total
        end

        total += 1000 # added to account for consumables, water, coal, etc

        if currency == 'kronars'
          return total
        elsif currency == 'lirums'
          return (total * 0.800).ceil
        elsif currency == 'dokoras'
          return (total * 0.7216).ceil
        end
      end

      # Repairs crafting tools
      #
      # @param info [Hash] crafting location info
      # @param tools [Array<String>] tools to repair
      # @param bag [String] container name
      # @param bag_items [Array<String>] items in container
      # @param belt [Hash] belt information
      # @return [void]
      def repair_own_tools(info, tools, bag, bag_items, belt)
        UserVars.immune_list ||= {} # declaring a hash unless hash already
        tools = tools.to_a # Convert single tool string to array
        UserVars.immune_list.reject! { |_k, v| v < Time.now } # removing anything from the immune list that has an expired timer
        tools.reject! { |x| UserVars.immune_list[x] } # removing tools from the list of eligible repairs if they're still on the immune list
        return unless tools.size > 0 # skips the whole method if no tools are eligible for repairs

        DRCC.check_consumables('oil', info['finisher-room'], info['finisher-number'], bag, bag_items, belt, tools.size) # checks intelligently for enough oil uses to repair the number of tools eligible for repair
        DRCC.check_consumables('wire brush', info['finisher-room'], 10, bag, bag_items, belt, tools.size) # checks intelligently for enough brush uses to repair the number of tools eligible for repair
        repair_tool = ['wire brush', 'oil']
        tools.each do |tool_name| # begins repair cycle for each tool
          DRCC.get_crafting_item(tool_name, bag, bag_items, belt, true) # attempts to fetch the next tool, with the option (true) to continue if fetch fails
          next unless DRC.right_hand # if we don't get the next tool for whatever reason, we move on to the next tool.

          repair_tool.each do |x| # iterates once for each: wire brush, oil
            DRCC.get_crafting_item(x, bag, bag_items, belt)
            command = x == 'wire brush' ? "rub my #{tool_name} with my wire brush" : "pour my oil on my #{tool_name}" # changes the command based on the tool, instead of a second case statement, since it's just one of each

            case DRC.bput(command, 'Roundtime', 'not damaged enough',
                          'You cannot do that while engaged!', 'cannot figure out how', 'Pour what')
            when 'Roundtime' # successful partial repair (one brush or one oil)
              DRCC.stow_crafting_item(x, bag, belt)
              next # move to oil, or move out of loop
            when 'not damaged enough' # doesn't require repair, leaving loop for the next tool
              DRCC.stow_crafting_item(x, bag, belt)
              break # leave brush/oil loop and choose next tool
            when 'Pour what'
              DRCC.check_consumables('oil', info['finisher-room'], info['finisher-number'], bag, bag_items, belt) # somehow ran out of oil, fetching more
              DRCC.get_crafting_item(x, bag, bag_items, belt)
              DRC.bput("pour my oil on my #{tool_name}", 'Roundtime')
              DRCC.stow_crafting_item(x, bag, belt)
              next # oil done, next tool
            when 'You cannot do that while engaged!'
              DRC.message("Cannot repair in combat")
              DRCC.stow_crafting_item(tool_name, bag, belt)
              DRCC.stow_crafting_item(x, bag, belt)
              break
            when 'cannot figure out how'
              DRC.message("Something has gone wrong, exiting repair")
              DRCC.stow_crafting_item(tool_name, bag, belt)
              DRCC.stow_crafting_item(x, bag, belt)
              break
            end
          end
          UserVars.immune_list.store(tool_name, Time.now + 7000) if Flags['proper-repair'] # if our flag picks up a Proper Forging Tool Care successful repair, we add that tool and a time of now plus 7000 seconds (just shy of 2 hours) to the list of immune tools
          Flags.reset('proper-repair')
          DRCC.stow_crafting_item(tool_name, bag, belt)
        end
        return
      end

      # Checks and restocks consumable items
      #
      # @param name [String] name of consumable
      # @param room [Integer] room number to buy from
      # @param number [Integer] order number
      # @param bag [String] container name
      # @param bag_items [Array<String>] items in container
      # @param belt [Hash] belt information
      # @param count [Integer] minimum required uses
      # @return [void]
      def check_consumables(name, room, number, bag, bag_items, belt, count = 3)
        current = Room.current.id
        case DRC.bput("get my #{name} from my #{bag}", 'You get', 'What were')
        when 'You get'
          /(\d+)/ =~ DRC.bput("count my #{name}", 'The .* has (\d+) uses remaining', 'You count out (\d+) yards of material there')
          if Regexp.last_match(1).to_i < count
            DRCT.dispose(name)
            DRCC.check_consumables(name, room, number, bag, bag_items, belt, count)
          end
          DRCC.stow_crafting_item(name, bag, belt)
        else
          DRCT.order_item(room, number)
          DRCC.stow_crafting_item(name, bag, belt)
        end
        DRCT.walk_to(current)
      end

      # Gets and adjusts tongs for different uses
      #
      # @param usage [String] desired tongs configuration ('shovel'/'tongs')
      # @param bag [String] container name
      # @param bag_items [Array<String>] items in container
      # @param belt [Hash] belt information
      # @param adjustable_tongs [Boolean] whether tongs can be adjusted
      # @return [Boolean] true if tongs ready in desired configuration
      def get_adjust_tongs?(usage, bag, bag_items, belt, adjustable_tongs = false)
        case usage
        when 'shovel' # looking for a shovel
          if @tongs_status == 'shovel' # tongs already a shovel
            DRCC.get_crafting_item('tongs', bag, bag_items, belt) unless DRCI.in_hands?('tongs') # get unless already holding
            return true # tongs previously set to shovel, in hands, adjusted to shovel.
          elsif !adjustable_tongs # determines state of tongs, works either nil or tongs
            return false # non-adjustable
          else
            DRCC.get_crafting_item('tongs', bag, bag_items, belt) unless DRCI.in_hands?('tongs') # get unless already holding

            case DRC.bput("adjust my tongs", 'You lock the tongs', 'With a yank you fold the shovel', 'You cannot adjust', 'You have no idea how')
            when 'You cannot adjust', 'You have no idea how' # holding tongs, not adjustable, settings are wrong.
              DRC.message('Tongs are not adjustable. Please change yaml to reflect adjustable_tongs: false')
              DRCC.stow_crafting_item('tongs', bag, belt) # stows to make room for shovel
              return false
            when 'With a yank you fold the shovel' # now tongs, adjust success but in wrong configuration
              DRC.bput("adjust my tongs", 'You lock the tongs') # now shovel, ready to work
              @tongs_status = 'shovel' # correcting instance variable
              return true # tongs as shovel
            when 'You lock the tongs' # now shovel, adjust success
              @tongs_status = 'shovel' # setting instance variable
              return true # tongs as shovel
            end
          end

          # at this point, we either have tongs-in-shovel and a return of true, or tongs stowed(if in left hand) and a return of false

        when 'tongs' # looking for tongs
          DRCC.get_crafting_item('tongs', bag, bag_items, belt) unless DRCI.in_hands?('tongs') # get unless already holding. Here we are always getting tongs, never stowing tongs.
          if @tongs_status == 'tongs' # tongs as tongs already
            return true # tongs previously set to tongs, in hands, adjusted to tongs. this will not catch unscripted adjustments to tongs.
          elsif !adjustable_tongs # determines state of tongs, works either nil or shovel
            return false # have tongs, as tongs, but not adjustable.
          else

            case DRC.bput("adjust my tongs", 'You lock the tongs', 'With a yank you fold the shovel', 'You cannot adjust', 'You have no idea how')
            when 'You cannot adjust', 'You have no idea how' # holding tongs, not adjustable, settings are wrong.
              DRC.message('Tongs are not adjustable. Please change yaml to reflect adjustable_tongs: false')
              return false # here we have tongs in hand, as tongs, but they're not adjustable, so this returns false.
            when 'You lock the tongs' # now in shovel, adjust success but in wrong configuration
              DRC.bput("adjust my tongs", 'With a yank you fold the shovel') # now tongs, ready to work
              @tongs_status = 'tongs'
              return true # tongs as tongs AND adjustable
            when 'With a yank you fold the shovel' # now tongs
              @tongs_status = 'tongs'
              return true # tongs as tongs AND adjustable
            end
          end

        when 'reset shovel', 'reset tongs' # Used at the top of a script, to determine state of tongs.
          @tongs_status = nil
          adjustable_tongs = true
          if usage == 'reset shovel'
            return DRCC.get_adjust_tongs?('shovel', bag, bag_items, belt, adjustable_tongs)
          elsif usage == 'reset tongs'
            return DRCC.get_adjust_tongs?('tongs', bag, bag_items, belt, adjustable