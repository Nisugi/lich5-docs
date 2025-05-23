module Lich
  # module Gemstone # test this?
  module Claim
    Lock            = Mutex.new
    @claimed_room ||= nil
    @last_room    ||= nil
    @mine         ||= false
    @buffer         = []
    @others         = []
    @timestamp      = Time.now

    # Claims a room by its ID.
    #
    # @param id [Integer, String] The ID of the room to claim.
    # @return [void]
    # @raise [StandardError] If there is an issue with claiming the room.
    # @example
    #   Claim.claim_room(123)
    def self.claim_room(id)
      @claimed_room = id.to_i
      @timestamp    = Time.now
      Log.out("claimed #{@claimed_room}", label: %i(claim room)) if defined?(Log)
      Lock.unlock
    end

    # Returns the ID of the currently claimed room.
    #
    # @return [Integer, nil] The ID of the claimed room or nil if none.
    # @example
    #   claimed_id = Claim.claimed_room
    def self.claimed_room
      @claimed_room
    end

    # Returns the ID of the last room checked.
    #
    # @return [Integer, nil] The ID of the last room or nil if none.
    # @example
    #   last_id = Claim.last_room
    def self.last_room
      @last_room
    end

    # Locks the mutex for the Claim module.
    #
    # @return [void]
    # @note This method will only lock if the mutex is not already owned.
    # @example
    #   Claim.lock
    def self.lock
      Lock.lock if !Lock.owned?
    end

    # Unlocks the mutex for the Claim module.
    #
    # @return [void]
    # @note This method will only unlock if the mutex is owned.
    # @example
    #   Claim.unlock
    def self.unlock
      Lock.unlock if Lock.owned?
    end

    # Checks if the current instance is the owner of the claimed room.
    #
    # @return [Boolean] True if this instance is the owner, false otherwise.
    # @example
    #   is_mine = Claim.current?
    def self.current?
      Lock.synchronize { @mine.eql?(true) }
    end

    # Checks if the specified room has been checked.
    #
    # @param room [Integer, nil] The room ID to check. Defaults to the last room if nil.
    # @return [Boolean] True if the room has been checked, false otherwise.
    # @example
    #   has_checked = Claim.checked?(123)
    def self.checked?(room = nil)
      Lock.synchronize { XMLData.room_id == (room || @last_room) }
    end

    # Provides information about the current claim status and related data.
    #
    # @return [void]
    # @example
    #   Claim.info
    def self.info
      rows = [['XMLData.room_id', XMLData.room_id, 'Current room according to the XMLData'],
              ['Claim.mine?', Claim.mine?, 'Claim status on the current room'],
              ['Claim.claimed_room', Claim.claimed_room, 'Room id of the last claimed room'],
              ['Claim.checked?', Claim.checked?, "Has Claim finished parsing ROOMID\ndefault: the current room"],
              ['Claim.last_room', Claim.last_room, 'The last room checked by Claim, regardless of status'],
              ['Claim.others', Claim.others.join("\n"), "Other characters in the room\npotentially less grouped characters"]]
      info_table = Terminal::Table.new :headings => ['Property', 'Value', 'Description'],
                                       :rows     => rows,
                                       :style    => { :all_separators => true }
      Lich::Messaging.mono(info_table.to_s)
    end

    # Checks if the current instance is the owner of the claimed room.
    #
    # @return [Boolean] True if this instance is the owner, false otherwise.
    # @example
    #   is_mine = Claim.mine?
    def self.mine?
      self.current?
    end

    # Returns the list of other characters in the room.
    #
    # @return [Array] An array of other characters.
    # @example
    #   other_characters = Claim.others
    def self.others
      @others
    end

    # Returns the members of the group if checked.
    #
    # @return [Array] An array of group members' nouns or an empty array if not checked.
    # @example
    #   group_members = Claim.members
    def self.members
      return [] unless defined? Group

      begin
        if Group.checked?
          return Group.members.map(&:noun)
        else
          return []
        end
      rescue
        return []
      end
    end

    # Returns the connected clusters if defined.
    #
    # @return [Array] An array of connected clusters or an empty array if not defined.
    # @example
    #   connected_clusters = Claim.clustered
    def self.clustered
      begin
        return [] unless defined? Cluster
        Cluster.connected
      rescue
        return []
      end
    end

    # Handles the claim parsing for a given room and characters.
    #
    # @param nav_rm [Integer] The room ID being navigated to.
    # @param pcs [Array] The list of characters present in the room.
    # @return [void]
    # @raise [StandardError] If there is an error during parsing.
    # @example
    #   Claim.parser_handle(123, ['Alice', 'Bob'])
    def self.parser_handle(nav_rm, pcs)
      echo "Claim handled #{nav_rm} with xmlparser" if $claim_debug
      begin
        @others = pcs - self.clustered - self.members
        @last_room = nav_rm
        unless @others.empty?
          @mine = false
          return
        end
        @mine = true
        self.claim_room nav_rm unless nav_rm.nil?
      rescue StandardError => e
        if defined?(Log)
          Log.out(e)
        else
          respond("Claim Parser Error: #{e}")
        end
      ensure
        Lock.unlock if Lock.owned?
      end
    end
  end
  # end
end