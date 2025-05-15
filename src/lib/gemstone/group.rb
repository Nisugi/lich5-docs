require "ostruct"
require "benchmark"
require_relative 'disk'

module Lich
  module Gemstone
    # Handles group management, membership tracking, and group-related actions
    #
    # This class maintains the state of the current group, including members,
    # leadership status, and provides methods for group operations.
    class Group
      @@members ||= []
      @@leader  ||= nil
      @@checked ||= false
      @@status  ||= :closed

      # Clears all group members and resets checked status
      #
      # @return [void]
      def self.clear()
        @@members = []
        @@checked = false
      end

      # Checks if group status has been verified
      #
      # @return [Boolean] true if group status has been checked
      def self.checked?
        @@checked
      end

      # Adds one or more members to the group
      #
      # @param members [Array<GameObj>] The members to add to the group
      # @return [void]
      def self.push(*members)
        members.each do |member|
          @@members.push(member) unless include?(member)
        end
      end

      # Removes one or more members from the group
      #
      # @param members [Array<GameObj>] The members to remove
      # @return [void]
      def self.delete(*members)
        gone = members.map(&:id)
        @@members.reject! do |m| gone.include?(m.id) end
      end

      # Replaces all group members with new list
      #
      # @param members [Array<GameObj>] The new member list
      # @return [void]
      def self.refresh(*members)
        @@members = members.dup
      end

      # Gets current group members, checking status if needed
      #
      # @return [Array<GameObj>] Copy of current group members
      def self.members
        maybe_check
        @@members.dup
      end

      # Gets raw member list without status check
      #
      # @return [Array<GameObj>] Internal member array
      def self._members
        @@members
      end

      # Gets disk objects for all group members
      #
      # @return [Array<Disk>] Array of disk objects for group members
      def self.disks
        return [Disk.find_by_name(Char.name)].compact if Group.leader? && members.empty?
        member_disks = members.map(&:noun).map { |noun| Disk.find_by_name(noun) }.compact
        member_disks.push(Disk.find_by_name(Char.name)) if Disk.find_by_name(Char.name)
        return member_disks
      end

      # String representation of group members
      #
      # @return [String] String showing group members
      def self.to_s
        @@members.to_s
      end

      # Sets the checked status flag
      #
      # @param flag [Boolean] New checked status
      # @return [void]
      def self.checked=(flag)
        @@checked = flag
      end

      # Sets the group status (open/closed)
      # 
      # @param state [Symbol] :open or :closed
      # @return [void]
      def self.status=(state)
        @@status = state
      end

      # Gets current group status
      #
      # @return [Symbol] :open or :closed
      def self.status()
        @@status
      end

      # Checks if group is open to new members
      #
      # @return [Boolean] true if group is open
      def self.open?
        maybe_check
        @@status.eql?(:open)
      end

      # Checks if group is closed to new members
      #
      # @return [Boolean] true if group is closed
      def self.closed?
        not open?
      end

      # Performs initial group status check
      #
      # @return [Array<GameObj>] Current group members
      # @note Waits up to 3 seconds for response
      def self.check
        Group.clear()
        ttl = Time.now + 3
        Game._puts "<c>group\r\n"
        wait_until { Group.checked? or Time.now > ttl }
        @@members.dup
      end

      # Checks group status if not already checked
      #
      # @return [void]
      def self.maybe_check
        Group.check unless checked?
      end

      # Gets list of PCs not in the group
      #
      # @return [Array<GameObj>] PCs that aren't group members
      def self.nonmembers
        GameObj.pcs.to_a.reject { |pc| ids.include?(pc.id) }
      end

      # Sets group leader
      #
      # @param char [GameObj, Symbol] Character object or :self
      # @return [void]
      def self.leader=(char)
        @@leader = char
      end

      # Gets current group leader
      #
      # @return [GameObj, Symbol] Leader object or :self
      def self.leader
        @@leader
      end

      # Checks if current character is group leader
      #
      # @return [Boolean] true if self is leader
      def self.leader?
        @@leader.eql?(:self)
      end

      # Attempts to add members to group
      #
      # @param members [Array<String, GameObj>] Members to add
      # @return [Array<Hash>] Results of add attempts
      # @example
      #   Group.add("PlayerName") #=> [{ok: player_obj}]
      def self.add(*members)
        members.map do |member|
          if member.is_a?(Array)
            Group.add(*member)
          else
            member = GameObj.pcs.find { |pc| pc.noun.eql?(member) } if member.is_a?(String)

            break if member.nil?

            result = dothistimeout("group ##{member.id}", 3, Regexp.union(
                                                               %r{You add #{member.noun} to your group},
                                                               %r{#{member.noun}'s group status is closed},
                                                               %r{But #{member.noun} is already a member of your group}
                                                             ))

            case result
            when %r{You add}, %r{already a member}
              Group.push(member)
              { ok: member }
            when %r{closed}
              Group.delete(member)
              { err: member }
            else
            end
          end
        end
      end

      # Gets IDs of all group members
      #
      # @return [Array<String>] Member IDs
      def self.ids
        @@members.map(&:id)
      end

      # Gets nouns/names of all group members
      #
      # @return [Array<String>] Member names
      def self.nouns
        @@members.map(&:noun)
      end

      # Checks if specified members are in group
      #
      # @param members [Array<GameObj>] Members to check
      # @return [Boolean] true if all specified members are in group
      def self.include?(*members)
        members.all? { |m| ids.include?(m.id) }
      end

      # Checks if group state is broken/invalid
      #
      # @return [Boolean] true if group state is invalid
      def self.broken?
        sleep(0.1) while Lich::Gemstone::Claim::Lock.locked?
        if Group.leader?
          return true if (GameObj.pcs.empty? || GameObj.pcs.nil?) && !@@members.empty?
          return false if (GameObj.pcs.empty? || GameObj.pcs.nil?) && @@members.empty?
          (GameObj.pcs.map(&:noun) & @@members.map(&:noun)).size < @@members.size
        else
          GameObj.pcs.find do |pc| pc.noun.eql?(Group.leader.noun) end.nil?
        end
      end

      def self.method_missing(method, *args, &block)
        @@members.send(method, *args, &block)
      end
    end

    class Group
      # Handles parsing and processing of group-related game messages
      module Observer
        # Collection of regex patterns for parsing group-related messages
        module Term
          # Matches group join message
          JOIN    = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> joins your group.\r?\n?$}
          # Matches group leave message
          LEAVE   = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> leaves your group.\r?\n?$}
          # Matches group add message
          ADD     = %r{^You add <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> to your group.\r?\n?$}
          # Matches group remove message
          REMOVE  = %r{^You remove <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> from the group.\r?\n?$}
          NOOP    = %r{^But <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> is already a member of your group!\r?\n?$}
          HAS_LEADER = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> designates you as the new leader of the group\.\r?\n?$}
          SWAP_LEADER = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> designates <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> as the new leader of the group.\r?\n?$}
          GAVE_LEADER_AWAY = %r{You designate <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> as the new leader of the group\.\r?\n?$}
          DISBAND = %r{^You disband your group}
          ADDED_TO_NEW_GROUP = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> adds you to <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> group.\r?\n?$}
          JOINED_NEW_GROUP = %r{You join <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a>\.\r?\n?$}
          LEADER_ADDED_MEMBER = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> adds <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> to <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> group\.\r?\n?$}
          LEADER_REMOVED_MEMBER = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> removes <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> from the group\.\r?\n?$}
          HOLD_RESERVED_FIRST = %r{^You grab <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand.\r?\n?$}
          HOLD_NEUTRAL_FIRST = %r{^You reach out and hold <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand.\r?\n?$}
          HOLD_FRIENDLY_FIRST = %r{^You gently take hold of <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand.\r?\n?$}
          HOLD_WARM_FIRST = %r{^You clasp <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand tenderly.\r?\n?$}
          HOLD_RESERVED_SECOND = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> grabs your hand.\r?\n?$}
          HOLD_NEUTRAL_SECOND = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> reaches out and holds your hand.\r?\n?$}
          HOLD_FRIENDLY_SECOND = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> gently takes hold of your hand.\r?\n?$}
          HOLD_WARM_SECOND = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> clasps your hand tenderly.\r?\n?$}
          HOLD_RESERVED_THIRD = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> grabs <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand.\r?\n?$}
          HOLD_NEUTRAL_THIRD = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> reaches out and holds <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand.\r?\n?$}
          HOLD_FRIENDLY_THIRD = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> gently takes hold of <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand.\r?\n?$}
          HOLD_WARM_THIRD = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> clasps <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand tenderly.\r?\n?$}
          OTHER_JOINED_GROUP = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> joins <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> group.\r?\n?$}

          NO_GROUP = /^You are not currently in a group/
          MEMBER   = /^You are (?:leading|grouped with) (.*)/
          STATUS   = /^Your group status is currently (?<status>open|closed)\./

          GROUP_EMPTIED    = %[<indicator id='IconJOINED' visible='n'/>]
          GROUP_EXISTS     = %[<indicator id='IconJOINED' visible='y'/>]
          GIVEN_LEADERSHIP = %[designates you as the new leader of the group.]

          ANY = Regexp.union(
            JOIN,
            LEAVE,
            ADD,
            REMOVE,
            DISBAND,
            NOOP,
            STATUS,
            NO_GROUP,
            MEMBER,
            HAS_LEADER,
            SWAP_LEADER,
            LEADER_ADDED_MEMBER,
            LEADER_REMOVED_MEMBER,
            ADDED_TO_NEW_GROUP,
            JOINED_NEW_GROUP,
            GAVE_LEADER_AWAY,
            HOLD_RESERVED_FIRST,
            HOLD_NEUTRAL_FIRST,
            HOLD_FRIENDLY_FIRST,
            HOLD_WARM_FIRST,
            HOLD_RESERVED_SECOND,
            HOLD_NEUTRAL_SECOND,
            HOLD_FRIENDLY_SECOND,
            HOLD_WARM_SECOND,
            HOLD_RESERVED_THIRD,
            HOLD_NEUTRAL_THIRD,
            HOLD_FRIENDLY_THIRD,
            HOLD_WARM_THIRD,
            OTHER_JOINED_GROUP,
          )

          EXIST = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a>}
        end

        # Extracts character references from XML
        #
        # @param xml [String] XML string to parse
        # @return [Array<GameObj>] Referenced game objects
        def self.exist(xml)
          xml.scan(Group::Observer::Term::EXIST).map { |id, _noun, _name| GameObj[id] }
        end

        # Checks if a line contains group-related messages
        #
        # @param line [String] Line to check
        # @return [Boolean] true if line contains group messages
        def self.wants?(line)
          line.strip.match(Term::ANY) or
            line.include?(Term::GROUP_EMPTIED)
        end

        # Processes a group-related message line
        #
        # @param line [String] Message to process
        # @param match_data [MatchData] Regex match data
        # @return [void]
        def self.consume(line, match_data)
          if line.include?(Term::GIVEN_LEADERSHIP)
            return Group.leader = :self
          end

          if line.include?(Term::GROUP_EMPTIED)
            Group.leader = :self
            return Group._members.clear
          end

          people = exist(line)

          if line.include?("You are leading")
            Group.leader = :self
          elsif line.include?("You are grouped with")
            Group.leader = people.first
          end

          case line
          when Term::NO_GROUP, Term::DISBAND
            Group.leader = :self
            return Group._members.clear
          when Term::STATUS
            Group.status = match_data[:status].to_sym
            return Group.checked = true
          when Term::GAVE_LEADER_AWAY
            Group.push(people.first)
            return Group.leader = people.first
          when Term::ADDED_TO_NEW_GROUP, Term::JOINED_NEW_GROUP
            Group.checked = false
            Group.push(people.first)
            return Group.leader = people.first
          when Term::SWAP_LEADER
            (old_leader, new_leader) = people
            Group.push(*people) if Group.include?(old_leader) or Group.include?(new_leader)
            return Group.leader = new_leader
          when Term::LEADER_ADDED_MEMBER
            (leader, added) = people
            Group.push(added) if Group.include?(leader)
          when Term::LEADER_REMOVED_MEMBER
            (leader, removed) = people
            return Group.delete(removed) if Group.include?(leader)
          when Term::JOIN, Term::ADD, Term::NOOP
            return Group.push(*people)
          when Term::MEMBER
            return Group.refresh(*people)
          when Term::HOLD_FRIENDLY_FIRST, Term::HOLD_NEUTRAL_FIRST, Term::HOLD_RESERVED_FIRST, Term::HOLD_WARM_FIRST
            return Group.push(people.first)
          when Term::HOLD_FRIENDLY_SECOND, Term::HOLD_NEUTRAL_SECOND, Term::HOLD_RESERVED_SECOND, Term::HOLD_WARM_SECOND
            Group.checked = false
            Group.push(people.first)
            return Group.leader = people.first
          when Term::HOLD_FRIENDLY_THIRD, Term::HOLD_NEUTRAL_THIRD, Term::HOLD_RESERVED_THIRD, Term::HOLD_WARM_THIRD
            (leader, added) = people
            Group.push(added) if Group.include?(leader)
          when Term::OTHER_JOINED_GROUP
            (added, leader) = people
            Group.push(added) if Group.include?(leader)
          when Term::LEAVE, Term::REMOVE
            return Group.delete(*people)
          end
        end
      end
    end
  end
end