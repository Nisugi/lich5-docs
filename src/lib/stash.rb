# Core module for the Lich game scripting system
module Lich

  # Provides functionality for managing items and containers in hands and inventory
  # Extends free_hands and empty_hands functions with container-aware capabilities
  module Stash

    # Locates a container in the player's inventory by name
    #
    # @param param [String, GameObj] Container name or GameObj to search for
    # @param loud_fail [Boolean] Whether to raise an error if container not found
    # @return [GameObj, nil] The found container object or nil if not found
    # @raise [RuntimeError] When container not found and loud_fail is true
    # @example
    #   Lich::Stash.find_container("backpack")
    #   Lich::Stash.find_container(some_game_obj, loud_fail: false)
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

    # Gets or initializes a container, ensuring it's open and contents are visible
    #
    # @param param [String, GameObj] Container name or object to initialize
    # @return [GameObj] The initialized container object
    # @example
    #   container = Lich::Stash.container("backpack")
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

    # Attempts to execute a command with timeout and verification
    #
    # @param seconds [Integer] Timeout duration in seconds
    # @param command [String] Command to execute
    # @return [Boolean] True if successful, false otherwise
    # @raise [RuntimeError] When command fails or times out
    # @example
    #   Lich::Stash.try_or_fail(seconds: 3, command: "get gem") { condition_met? }
    def self.try_or_fail(seconds: 2, command: nil)
      fput(command)
      expiry = Time.now + seconds
      wait_until do yield or Time.now > expiry end
      fail "Error[command: #{command}, seconds: #{seconds}]" if Time.now > expiry
    end

    # Adds an item to a specified container
    #
    # @param bag [String, GameObj] Container to add item to
    # @param item [GameObj] Item to add to container
    # @return [Boolean] True if successful, false if failed
    # @example
    #   Lich::Stash.add_to_bag("backpack", sword)
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

    # Moves an item from hands to worn inventory
    #
    # @param item [GameObj] Item to wear
    # @return [Boolean] True if successful, false if failed
    # @example
    #   Lich::Stash.wear_to_inv(shield)
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

    # Initializes sheath information from ready list settings
    #
    # @note Updates @sheath hash with primary and secondary sheath information
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

    # Checks if primary sheath is missing from inventory
    #
    # @return [Boolean] True if primary sheath is missing
    # @example
    #   Lich::Stash.missing_primary_sheath?
    def self.missing_primary_sheath? # check entry against actual inventory to catch inventory updatees
      @sheath.has_key?(:sheath) && !GameObj.inv.any? { |item| item.id == @sheath[:sheath].id }
    end

    # Checks if secondary sheath is missing from inventory
    #
    # @return [Boolean] True if secondary sheath is missing
    # @example
    #   Lich::Stash.missing_secondary_sheath?
    def self.missing_secondary_sheath? # check entry against actual inventory to catch inventory updates
      @sheath.has_key?(:secondary_sheath) && !GameObj.inv.any? { |item| item.id == @sheath[:secondary_sheath].id }
    end

    # Stores items from hands into appropriate containers
    #
    # @param right [Boolean] Whether to stash right hand
    # @param left [Boolean] Whether to stash left hand
    # @param both [Boolean] Whether to stash both hands
    # @note Prioritizes sheaths for weapons, then weaponsack, then lootsack
    # @example
    #   Lich::Stash.stash_hands(right: true)
    #   Lich::Stash.stash_hands(both: true)
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

    # Retrieves previously stashed items back to hands
    #
    # @param right [Boolean] Whether to equip right hand
    # @param left [Boolean] Whether to equip left hand
    # @param both [Boolean] Whether to equip both hands
    # @example
    #   Lich::Stash.equip_hands(left: true)
    #   Lich::Stash.equip_hands(both: true)
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