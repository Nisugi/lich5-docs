=begin
stash.rb: Core lich file for extending free_hands, empty_hands functions in
  item / container script indifferent method.  Usage will ensure no regex is
  required to be maintained.
=end

module Lich
  module Stash
    # Finds a container by its name.
    #
    # @param param [String, GameObj] The name of the container or a GameObj instance.
    # @param loud_fail [Boolean] Whether to raise an error if the container is not found. Default is true.
    # @return [GameObj, nil] The found container or nil if not found.
    # @raise [RuntimeError] If the container is not found and loud_fail is true.
    # @example
    #   container = Lich::Stash.find_container("my_container")
    def self.find_container(param, loud_fail: true)
      param = param.name if param.is_a?(GameObj) # (Lich::Gemstone::GameObj)
      found_container = GameObj.inv.find do |container|
        container.name =~ %r[#{param.strip}]i || container.name =~ %r[#{param.sub(' ', ' .*')}]i
      end
      if found_container.nil? && loud_fail
        fail "could not find Container[name: #{param}]"
      else
        return found_container
      end
    end

    # Retrieves a container and ensures it is displayed.
    #
    # @param param [String] The name of the container.
    # @return [GameObj] The found container.
    # @example
    #   container = Lich::Stash.container("my_container")
    def self.container(param)
      @weapon_displayer ||= []
      container_to_check = find_container(param)
      unless @weapon_displayer.include?(container_to_check.id)
        result = Lich::Util.issue_command("look in ##{container_to_check.id}", /In the .*$|That is closed\.|^You glance at/, silent: true, quiet: true) if container_to_check.contents.nil?
        fput "open ##{container_to_check.id}" if result.include?('That is closed.')
        @weapon_displayer.push(container_to_check.id) if GameObj.containers.find { |item| item[0] == container_to_check.id }.nil?
      end
      return container_to_check
    end

    # Executes a command and waits for a specified duration.
    #
    # @param seconds [Integer] The number of seconds to wait before failing. Default is 2.
    # @param command [String] The command to execute.
    # @return [Boolean] True if the command was successful within the time limit.
    # @raise [RuntimeError] If the command does not succeed within the specified time.
    # @example
    #   Lich::Stash.try_or_fail(command: "some_command")
    def self.try_or_fail(seconds: 2, command: nil)
      fput(command)
      expiry = Time.now + seconds
      wait_until do yield or Time.now > expiry end
      fail "Error[command: #{command}, seconds: #{seconds}]" if Time.now > expiry
    end

    # Adds an item to a specified bag.
    #
    # @param bag [String] The name of the bag to add the item to.
    # @param item [GameObj] The item to be added to the bag.
    # @return [Boolean] True if the item was successfully added, false otherwise.
    # @example
    #   result = Lich::Stash.add_to_bag("my_bag", item)
    def self.add_to_bag(bag, item)
      bag = container(bag)
      try_or_fail(command: "_drag ##{item.id} ##{bag.id}") do
        20.times {
          return true if ![GameObj.right_hand, GameObj.left_hand].map(&:id).compact.include?(item.id) && @weapon_displayer.include?(bag.id)
          return true if (![GameObj.right_hand, GameObj.left_hand].map(&:id).compact.include?(item.id) and bag.contents.to_a.map(&:id).include?(item.id))
          return true if item.name =~ /^ethereal \w+$/ && ![GameObj.right_hand, GameObj.left_hand].map(&:id).compact.include?(item.id)
          sleep 0.1
        }
        return false
      end
    end

    # Wears an item to the inventory.
    #
    # @param item [GameObj] The item to wear.
    # @return [Boolean] True if the item was successfully worn, false otherwise.
    # @example
    #   result = Lich::Stash.wear_to_inv(item)
    def self.wear_to_inv(item)
      try_or_fail(command: "wear ##{item.id}") do
        20.times {
          return true if (![GameObj.right_hand, GameObj.left_hand].map(&:id).compact.include?(item.id) and GameObj.inv.to_a.map(&:id).include?(item.id))
          return true if item.name =~ /^ethereal \w+$/ && ![GameObj.right_hand, GameObj.left_hand].map(&:id).compact.include?(item.id)
          sleep 0.1
        }
        return false
      end
    end

    # Checks and retrieves the settings for sheaths.
    #
    # @return [void]
    # @example
    #   Lich::Stash.sheath_bags
    def self.sheath_bags
      # find ready list settings for sheaths only; regex courtesy Eloot
      @sheath = {}
      @checked_sheaths = false
      sheath_list_match = /(?:sheath|secondary sheath):\s+<d\scmd="store\s(\w+)\sclear">[^<]+<a\sexist="(\d+)"\snoun="[^"]+">([^<]+)<\/a>(?:\s[^<]+)?<\/d>/

      ready_lines = Lich::Util.issue_command("ready list", /Your current settings are/, /To change your default item for a category that is already set/, silent: true, quiet: true)
      ready_lines.each { |line|
        if line =~ sheath_list_match
          sheath_obj = Regexp.last_match(3).to_s.downcase
          sheath_type = Regexp.last_match(1).to_s.downcase.gsub('2', 'secondary_')
          found_container = Stash.find_container(sheath_obj, loud_fail: false)
          unless found_container.nil?
            @sheath.store(sheath_type.to_sym, found_container)
          else
            respond("Lich::Stash.sheath_bags Error: Could not find sheath(#{sheath_obj}) in inventory. Not using, possibly hidden, tucked, or missing.")
            Lich.log("Lich::Stash.sheath_bags Error: Could not find sheath(#{sheath_obj}) in inventory. Not using, possibly hidden, tucked, or missing.")
          end
        end
      }
      @checked_sheaths = true
    end

    # Checks if the primary sheath is missing from the inventory.
    #
    # @return [Boolean] True if the primary sheath is missing, false otherwise.
    # @example
    #   is_missing = Lich::Stash.missing_primary_sheath?
    def self.missing_primary_sheath? # check entry against actual inventory to catch inventory updatees
      @sheath.has_key?(:sheath) && !GameObj.inv.any? { |item| item.id == @sheath[:sheath].id }
    end

    # Checks if the secondary sheath is missing from the inventory.
    #
    # @return [Boolean] True if the secondary sheath is missing, false otherwise.
    # @example
    #   is_missing = Lich::Stash.missing_secondary_sheath?
    def self.missing_secondary_sheath? # check entry against actual inventory to catch inventory updates
      @sheath.has_key?(:secondary_sheath) && !GameObj.inv.any? { |item| item.id == @sheath[:secondary_sheath].id }
    end

    # Stashes items in the hands based on the specified parameters.
    #
    # @param right [Boolean] Whether to stash items in the right hand.
    # @param left [Boolean] Whether to stash items in the left hand.
    # @param both [Boolean] Whether to stash items in both hands.
    # @return [void]
    # @example
    #   Lich::Stash.stash_hands(right: true, left: false)
    def self.stash_hands(right: false, left: false, both: false)
      $fill_hands_actions ||= Array.new
      $fill_left_hand_actions ||= Array.new
      $fill_right_hand_actions ||= Array.new

      actions = Array.new
      right_hand = GameObj.right_hand
      left_hand = GameObj.left_hand

      # extending to use sheath / 2sheath wherever possible
      if !@checked_sheaths || missing_primary_sheath? || missing_secondary_sheath?
        Stash.sheath_bags # @checked_sheaths is set true when this method executes
      end
      if @sheath.has_key?(:sheath)
        unless @sheath.has_key?(:secondary_sheath)
          sheath = second_sheath = @sheath.fetch(:sheath)
        else
          sheath = @sheath.fetch(:sheath) if @sheath.has_key?(:sheath)
          second_sheath = @sheath.fetch(:secondary_sheath) if @sheath.has_key?(:secondary_sheath)
        end
      elsif @sheath.has_key?(:secondary_sheath)
        sheath = second_sheath = @sheath.fetch(:secondary_sheath)
      else
        sheath = second_sheath = nil
      end
      # weaponsack for both hands
      if UserVars.weapon.class == String and UserVars.weaponsack.class == String and not UserVars.weapon.empty? and not UserVars.weaponsack.empty? and (right_hand.name =~ /#{Regexp.escape(UserVars.weapon.strip)}/i or right_hand.name =~ /#{Regexp.escape(UserVars.weapon).sub(' ', ' .*')}/i)
        weaponsack = nil unless (weaponsack = find_container(UserVars.weaponsack, loud_fail: false)).is_a?(GameObj) # (Lich::Gemstone::GameObj)
      end
      # lootsack for both hands
      if UserVars.lootsack.class != String || UserVars.lootsack.empty?
        lootsack = nil
      else
        lootsack = nil unless (lootsack = find_container(UserVars.lootsack, loud_fail: false)).is_a?(GameObj) # (Lich::Gemstone::GameObj)
      end
      # finding another container if needed
      other_containers_var = nil
      other_containers = proc {
        results = Lich::Util.issue_command('inventory containers', /^(?:You are carrying nothing at this time|You are wearing)/, silent: true, quiet: true)
        other_containers_ids = results.to_s.scan(/exist=\\"(.*?)\\"/).flatten - [lootsack.id]
        other_containers_var = GameObj.inv.find_all { |obj| other_containers_ids.include?(obj.id) }
        other_containers_var
      }

      if (left || both) && left_hand.id
        waitrt?
        if (left_hand.noun =~ /shield|buckler|targe|heater|parma|aegis|scutum|greatshield|mantlet|pavis|arbalest|bow|crossbow|yumi|arbalest/)\
          and Lich::Stash::wear_to_inv(left_hand)
          actions.unshift proc {
            fput "remove ##{left_hand.id}"
            20.times { break if GameObj.left_hand.id == left_hand.id or GameObj.right_hand.id == left_hand.id; sleep 0.1 }

            if GameObj.right_hand.id == left_hand.id
              dothistimeout 'swap', 3, /^You don't have anything to swap!|^You swap/
            end
          }
        else
          actions.unshift proc {
            if left_hand.name =~ /^ethereal \w+$/
              fput "rub #{left_hand.noun} tattoo"
              20.times { break if (GameObj.left_hand.name == left_hand.name) or (GameObj.right_hand.name == left_hand.name); sleep 0.1 }
            else
              fput "get ##{left_hand.id}"
              20.times { break if (GameObj.left_hand.id == left_hand.id) or (GameObj.right_hand.id == left_hand.id); sleep 0.1 }
            end

            if GameObj.right_hand.id == left_hand.id or (GameObj.right_hand.name == left_hand.name && left_hand.name =~ /^ethereal \w+$/)
              dothistimeout 'swap', 3, /^You don't have anything to swap!|^You swap/
            end
          }
          if !second_sheath.nil? && GameObj.left_hand.type =~ /weapon/
            result = Lich::Stash.add_to_bag(second_sheath, GameObj.left_hand)
          elsif weaponsack && GameObj.left_hand.type =~ /weapon/
            result = Lich::Stash::add_to_bag(weaponsack, GameObj.left_hand)
          elsif lootsack
            result = Lich::Stash::add_to_bag(lootsack, GameObj.left_hand)
          else
            result = nil
          end
          if result.nil? or !result
            for container in other_containers.call
              result = Lich::Stash::add_to_bag(container, GameObj.left_hand)
              break if result
            end
          end
        end
      end
      if (right || both) && right_hand.id
        waitrt?
        actions.unshift proc {
          if right_hand.name =~ /^ethereal \w+$/
            fput "rub #{right_hand.noun} tattoo"
            20.times { break if GameObj.left_hand.name == right_hand.name or GameObj.right_hand.name == right_hand.name; sleep 0.1 }
          else
            fput "get ##{right_hand.id}"
            20.times { break if GameObj.left_hand.id == right_hand.id or GameObj.right_hand.id == right_hand.id; sleep 0.1 }
          end

          if GameObj.left_hand.id == right_hand.id or (GameObj.left_hand.name == right_hand.name && right_hand.name =~ /^ethereal \w+$/)
            dothistimeout 'swap', 3, /^You don't have anything to swap!|^You swap/
          end
        }

        if !sheath.nil? && GameObj.right_hand.type =~ /weapon/
          result = Lich::Stash.add_to_bag(sheath, GameObj.right_hand)
        elsif weaponsack && GameObj.right_hand.type =~ /weapon/
          result = Lich::Stash::add_to_bag(weaponsack, GameObj.right_hand)
        elsif lootsack
          result = Lich::Stash::add_to_bag(lootsack, GameObj.right_hand)
        else
          result = nil
        end
        sleep 0.1
        if result.nil? or !result
          for container in other_containers.call
            result = Lich::Stash::add_to_bag(container, GameObj.right_hand)
            break if result
          end
        end
      end
      $fill_hands_actions.push(actions) if both
      $fill_left_hand_actions.push(actions) if left
      $fill_right_hand_actions.push(actions) if right
    end

    # Equips items in the hands based on the specified parameters.
    #
    # @param left [Boolean] Whether to equip items in the left hand.
    # @param right [Boolean] Whether to equip items in the right hand.
    # @param both [Boolean] Whether to equip items in both hands.
    # @return [void]
    # @example
    #   Lich::Stash.equip_hands(left: true)
    def self.equip_hands(left: false, right: false, both: false)
      if both
        for action in $fill_hands_actions.pop
          action.call
        end
      elsif left
        for action in $fill_left_hand_actions.pop
          action.call
        end
      elsif right
        for action in $fill_right_hand_actions.pop
          action.call
        end
      else
        if $fill_right_hand_actions.length > 0
          for action in $fill_right_hand_actions.pop
            action.call
          end
        elsif $fill_left_hand_actions.length > 0
          for action in $fill_left_hand_actions.pop
            action.call
          end
        end
      end
    end
  end
end