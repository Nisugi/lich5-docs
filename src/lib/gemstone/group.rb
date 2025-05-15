require "ostruct"
require "benchmark"
require_relative 'disk'

module Lich
  module Gemstone
    # Represents a group of members in the game.
    class Group
      @@members ||= []
      @@leader  ||= nil
      @@checked ||= false
      @@status  ||= :closed

      # Clears the group members and resets the checked status.
      #
      # @return [void]
      #
      # @example
      #   Group.clear
      def self.clear()
        @@members = []
        @@checked = false
      end

      # Checks if the group has been checked.
      #
      # @return [Boolean] true if checked, false otherwise
      #
      # @example
      #   Group.checked? # => false
      def self.checked?
        @@checked
      end

      # Adds members to the group if they are not already included.
      #
      # @param members [Array] the members to add
      # @return [void]
      #
      # @example
      #   Group.push(member1, member2)
      def self.push(*members)
        members.each do |member|
          @@members.push(member) unless include?(member)
        end
      end

      # Removes specified members from the group.
      #
      # @param members [Array] the members to remove
      # @return [void]
      #
      # @example
      #   Group.delete(member1, member2)
      def self.delete(*members)
        gone = members.map(&:id)
        @@members.reject! do |m| gone.include?(m.id) end
      end

      # Refreshes the group members with the provided members.
      #
      # @param members [Array] the new members to set
      # @return [void]
      #
      # @example
      #   Group.refresh(new_member1, new_member2)
      def self.refresh(*members)
        @@members = members.dup
      end

      # Retrieves a duplicate of the current group members.
      #
      # @return [Array] a duplicate array of group members
      #
      # @example
      #   members = Group.members
      def self.members
        maybe_check
        @@members.dup
      end

      # Retrieves the original group members without duplication.
      #
      # @return [Array] the original array of group members
      #
      # @example
      #   original_members = Group._members
      def self._members
        @@members
      end

      # Retrieves the disks associated with the group members.
      #
      # @return [Array] an array of Disk objects associated with the members
      #
      # @example
      #   disks = Group.disks
      def self.disks
        return [Disk.find_by_name(Char.name)].compact if Group.leader? && members.empty?
        member_disks = members.map(&:noun).map { |noun| Disk.find_by_name(noun) }.compact
        member_disks.push(Disk.find_by_name(Char.name)) if Disk.find_by_name(Char.name)
        return member_disks
      end

      # Returns a string representation of the group members.
      #
      # @return [String] string representation of the group members
      #
      # @example
      #   group_string = Group.to_s
      def self.to_s
        @@members.to_s
      end

      # Sets the checked status of the group.
      #
      # @param flag [Boolean] the new checked status
      # @return [void]
      #
      # @example
      #   Group.checked = true
      def self.checked=(flag)
        @@checked = flag
      end

      # Sets the status of the group.
      #
      # @param state [Symbol] the new status (:open or :closed)
      # @return [void]
      #
      # @example
      #   Group.status = :open
      def self.status=(state)
        @@status = state
      end

      # Retrieves the current status of the group.
      #
      # @return [Symbol] the current status of the group
      #
      # @example
      #   current_status = Group.status
      def self.status()
        @@status
      end

      # Checks if the group is open.
      #
      # @return [Boolean] true if the group is open, false otherwise
      #
      # @example
      #   is_open = Group.open?
      def self.open?
        maybe_check
        @@status.eql?(:open)
      end

      # Checks if the group is closed.
      #
      # @return [Boolean] true if the group is closed, false otherwise
      #
      # @example
      #   is_closed = Group.closed?
      def self.closed?
        not open?
      end

      # Initializes the group and checks its status.
      #
      # @return [Array] a duplicate of the group members
      #
      # @example
      #   members = Group.check
      #
      # @note This method will block until the group is checked or the time limit is reached.
      def self.check
        Group.clear()
        ttl = Time.now + 3
        Game._puts "<c>group\r\n"
        wait_until { Group.checked? or Time.now > ttl }
        @@members.dup
      end

      # Checks the group status if it hasn't been checked yet.
      #
      # @return [void]
      #
      # @example
      #   Group.maybe_check
      def self.maybe_check
        Group.check unless checked?
      end

      # Retrieves non-member characters.
      #
      # @return [Array] an array of non-member characters
      #
      # @example
      #   nonmembers = Group.nonmembers
      def self.nonmembers
        GameObj.pcs.to_a.reject { |pc| ids.include?(pc.id) }
      end

      # Sets the leader of the group.
      #
      # @param char [Object] the character to set as leader
      # @return [void]
      #
      # @example
      #   Group.leader = character
      def self.leader=(char)
        @@leader = char
      end

      # Retrieves the current leader of the group.
      #
      # @return [Object] the current leader of the group
      #
      # @example
      #   current_leader = Group.leader
      def self.leader
        @@leader
      end

      # Checks if the current character is the leader of the group.
      #
      # @return [Boolean] true if the current character is the leader, false otherwise
      #
      # @example
      #   is_leader = Group.leader?
      def self.leader?
        @@leader.eql?(:self)
      end

      # Adds members to the group, handling various input types.
      #
      # @param members [Array] the members to add
      # @return [Array] an array of results for each member added
      #
      # @example
      #   results = Group.add(member1, member2)
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

      # Retrieves the IDs of the group members.
      #
      # @return [Array] an array of member IDs
      #
      # @example
      #   member_ids = Group.ids
      def self.ids
        @@members.map(&:id)
      end

      # Retrieves the nouns of the group members.
      #
      # @return [Array] an array of member nouns
      #
      # @example
      #   member_nouns = Group.nouns
      def self.nouns
        @@members.map(&:noun)
      end

      # Checks if the specified members are included in the group.
      #
      # @param members [Array] the members to check
      # @return [Boolean] true if all members are included, false otherwise
      #
      # @example
      #   is_included = Group.include?(member1, member2)
      def self.include?(*members)
        members.all? { |m| ids.include?(m.id) }
      end

      # Checks if the group is broken based on the current game state.
      #
      # @return [Boolean] true if the group is broken, false otherwise
      #
      # @example
      #   is_broken = Group.broken?
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

      # Handles missing methods by delegating to the members array.
      #
      # @param method [Symbol] the method name
      # @param args [Array] the arguments for the method
      # @param block [Proc] an optional block
      # @return [Object] the result of the method call on members
      #
      # @example
      #   result = Group.some_missing_method(args)
      def self.method_missing(method, *args, &block)
        @@members.send(method, *args, &block)
      end
    end

    class Group
      module Observer
        module Term
          ##
          # Regular expressions for passive messages related to group membership.
          #
          # These patterns are used to match various messages that indicate changes
          # in group membership status.
          ##
          JOIN    = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> joins your group.\r?\n?$}
          LEAVE   = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> leaves your group.\r?\n?$}
          ADD     = %r{^You add <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> to your group.\r?\n?$}
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
          ##
          # Regular expressions for active messages related to group membership.
          #
          # These patterns are used to match various messages that indicate the current
          # status of group membership.
          ##
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

        ##
        # Scans the provided XML string for existing group members.
        #
        # @param xml [String] The XML string to scan for group member information.
        # @return [Array<GameObj>] An array of GameObj instances representing the members found.
        # @example
        #   members = Group::Observer.exist("<a exist='123' noun='Player'>Player</a>")
        ##
        def self.exist(xml)
          xml.scan(Group::Observer::Term::EXIST).map { |id, _noun, _name| GameObj[id] }
        end

        ##
        # Determines if the provided line contains any group-related messages.
        #
        # @param line [String] The line of text to check for group messages.
        # @return [Boolean] True if the line contains a group message, false otherwise.
        # @example
        #   is_group_message = Group::Observer.wants?("You add <a exist='123' noun='Player'>Player</a> to your group.")
        ##
        def self.wants?(line)
          line.strip.match(Term::ANY) or
            line.include?(Term::GROUP_EMPTIED)
        end

        ##
        # Consumes a line of text and updates the group state based on the message.
        #
        # @param line [String] The line of text to process.
        # @param match_data [MatchData] The data extracted from the line using a regex match.
        # @return [void]
        # @note This method modifies the state of the Group class directly.
        # @example
        #   Group::Observer.consume("You add <a exist='123' noun='Player'>Player</a> to your group.", match_data)
        ##
        def self.consume(line, match_data)
          if line.include?(Term::GIVEN_LEADERSHIP)
            return Group.leader = :self
          end

          ## Group indicator changed!
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