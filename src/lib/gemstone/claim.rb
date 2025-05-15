# A module for managing room claims and character presence tracking in the game
# 
# @author Lich5 Documentation Generator
module Lich
  module Claim
    # @!attribute [r] Lock
    #   @return [Mutex] Mutex for thread-safe operations
    Lock            = Mutex.new

    # @!attribute [r] claimed_room
    #   @return [Integer, nil] The ID of the currently claimed room
    @claimed_room ||= nil

    # @!attribute [r] last_room  
    #   @return [Integer, nil] The ID of the last room checked
    @last_room    ||= nil

    # @!attribute [r] mine
    #   @return [Boolean] Whether the current room is claimed by this character
    @mine         ||= false

    # @!attribute [r] buffer
    #   @return [Array] Buffer for room data
    @buffer         = []

    # @!attribute [r] others
    #   @return [Array<String>] List of other characters in the room
    @others         = []

    # @!attribute [r] timestamp
    #   @return [Time] Timestamp of last claim
    @timestamp      = Time.now

    # Claims a room for the current character
    #
    # @param id [Integer, String] The room ID to claim
    # @return [void]
    # @example
    #   Lich::Claim.claim_room(1234)
    #
    # @note Logs the claim if logging is enabled
    def self.claim_room(id)
      @claimed_room = id.to_i
      @timestamp    = Time.now
      Log.out("claimed #{@claimed_room}", label: %i(claim room)) if defined?(Log)
      Lock.unlock
    end

    # Gets the currently claimed room ID
    #
    # @return [Integer, nil] The ID of the claimed room
    # @example
    #   room_id = Lich::Claim.claimed_room
    def self.claimed_room
      @claimed_room
    end

    # Gets the last checked room ID
    #
    # @return [Integer, nil] The ID of the last room checked
    # @example
    #   last_room = Lich::Claim.last_room
    def self.last_room
      @last_room
    end

    # Acquires the claim lock
    #
    # @return [void] 
    # @note Only locks if not already owned
    # @example
    #   Lich::Claim.lock
    def self.lock
      Lock.lock if !Lock.owned?
    end

    # Releases the claim lock
    #
    # @return [void]
    # @note Only unlocks if owned by current thread
    # @example
    #   Lich::Claim.unlock
    def self.unlock
      Lock.unlock if Lock.owned?
    end

    # Checks if the current room is claimed by this character
    #
    # @return [Boolean] true if room is claimed by this character
    # @example
    #   if Lich::Claim.current?
    #     # Room is claimed by us
    #   end
    def self.current?
      Lock.synchronize { @mine.eql?(true) }
    end

    # Verifies if a specific room has been checked
    #
    # @param room [Integer, nil] Room ID to check (defaults to last room)
    # @return [Boolean] true if the room matches XMLData.room_id
    # @example
    #   if Lich::Claim.checked?(1234)
    #     # Room has been checked
    #   end
    def self.checked?(room = nil)
      Lock.synchronize { XMLData.room_id == (room || @last_room) }
    end

    # Displays detailed claim information in a formatted table
    #
    # @return [void]
    # @example
    #   Lich::Claim.info
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

    # Alias for current?
    #
    # @return [Boolean] true if room is claimed by this character
    # @example
    #   if Lich::Claim.mine?
    #     # Room is claimed by us
    #   end
    def self.mine?
      self.current?
    end

    # Gets list of other characters in the room
    #
    # @return [Array<String>] Array of character names
    # @example
    #   others = Lich::Claim.others
    def self.others
      @others
    end

    # Gets list of group members
    #
    # @return [Array<String>] Array of group member names
    # @note Returns empty array if Group is not defined
    # @example
    #   members = Lich::Claim.members
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

    # Gets list of clustered characters
    #
    # @return [Array<String>] Array of clustered character names
    # @note Returns empty array if Cluster is not defined
    # @example
    #   clustered = Lich::Claim.clustered
    def self.clustered
      begin
        return [] unless defined? Cluster
        Cluster.connected
      rescue
        return []
      end
    end

    # Handles room parsing and claim updates
    #
    # @param nav_rm [Integer] Room ID from navigation
    # @param pcs [Array<String>] List of characters in room
    # @return [void]
    # @raise [StandardError] If parsing fails
    # @example
    #   Lich::Claim.parser_handle(1234, ["Character1", "Character2"])
    #
    # @note Updates room claim status based on presence of other characters
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
end