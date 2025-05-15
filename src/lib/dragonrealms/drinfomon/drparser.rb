# frozen_string_literal: true

# Module for parsing DragonRealms game data and maintaining game state
#
# @author Lich5 Documentation Generator
module Lich
  module DragonRealms
    module DRParser
      # Contains regular expression patterns for parsing game output
      module Pattern
        # Pattern for parsing experience columns
        # @example Matches: "Sword: 100 34% Dabbling"
        ExpColumns = /(?:\s*(?<skill>[a-zA-Z\s]+)\b:\s*(?<rank>\d+)\s+(?<percent>\d+)%\s+(?<rate>[a-zA-Z\s]+)\b)/.freeze

        # Pattern for parsing brief experience output when enabled
        # @example Matches: "<component id='exp Sword'>Sword: 100 34% [12/34]</component>"
        BriefExpOn = %r{<component id='exp .*?<d cmd='skill (?<skill>[a-zA-Z\s]+)'.*:\s+(?<rank>\d+)\s+(?<percent>\d+)%\s*\[\s?(?<rate>\d+)\/34\].*?<\/component>}.freeze
        
        # Pattern for parsing brief experience output when disabled
        BriefExpOff = %r{<component id='exp .*?\b(?<skill>[a-zA-Z\s]+)\b:\s+(?<rank>\d+)\s+(?<percent>\d+)%\s+\b(?<rate>[a-zA-Z\s]+)\b.*?<\/component>}.freeze
        
        # Pattern for parsing character name, race and guild
        NameRaceGuild = /^Name:\s+\b(?<name>.+)\b\s+Race:\s+\b(?<race>.+)\b\s+Guild:\s+\b(?<guild>.+)\b\s+/.freeze
        
        # Pattern for parsing character gender, age and circle
        GenderAgeCircle = /^Gender:\s+\b(?<gender>.+)\b\s+Age:\s+\b(?<age>.+)\b\s+Circle:\s+\b(?<circle>.+)/.freeze
        
        # Pattern for parsing stat values
        StatValue = /(?<stat>Strength|Agility|Discipline|Intelligence|Reflex|Charisma|Wisdom|Stamina|Favors|TDPs)\s+:\s+(?<value>\d+)/.freeze
        
        # Pattern for parsing TDP values
        TDPValue = /You have (\d+) TDPs\./.freeze
        
        # Pattern for parsing encumbrance values
        EncumbranceValue = /^\s*Encumbrance\s+:\s+(?<encumbrance>[\w\s'?!]+)$/.freeze
        
        # Pattern for parsing luck values
        LuckValue = /^\s*Luck\s+:\s+.*\((?<luck>[-\d]+)\/3\)/.freeze
        
        # Pattern for parsing balance status
        BalanceValue = /^(?:You are|\[You're) (?<balance>#{Regexp.union(DR_BALANCE_VALUES)}) balanced?/.freeze
        
        # Pattern for parsing experience mindstate clearing
        ExpClearMindstate = %r{<component id='exp (?<skill>[a-zA-Z\s]+)'><\/component>}.freeze
        
        # Pattern for parsing room players
        RoomPlayers = %r{\'room players\'>Also here: (.*)\.</component>}.freeze
        
        # Pattern for parsing empty room players
        RoomPlayersEmpty = %r{\'room players\'></component>}.freeze
        
        # Pattern for parsing room objects
        RoomObjs = %r{\'room objs\'>(.*)</component>}.freeze
        
        # Pattern for parsing empty room objects
        RoomObjsEmpty = %r{\'room objs\'></component>}.freeze
        
        # Pattern for parsing group members
        GroupMembers = %r{<pushStream id="group"/>  (\w+):}.freeze
        
        # Pattern for parsing empty group
        GroupMembersEmpty = %r{<pushStream id="group"/>Members of your group:}.freeze
        
        # Pattern for parsing start of experience modifiers
        ExpModsStart = /^(<.*?\/>)?The following skills are currently under the influence of a modifier/.freeze
        
        # Pattern for parsing start of known spells
        KnownSpellsStart = /^You recall the spells you have learned/.freeze
        
        # Pattern for parsing start of barbarian abilities
        BarbarianAbilitiesStart = /^You know the (Berserks:)/.freeze
        
        # Pattern for parsing start of thief khri abilities
        ThiefKhriStart = /^From the Subtlety tree, you know the following khri:/.freeze
        
        # Pattern for parsing spell book format
        SpellBookFormat = /^You will .* (?<format>column-formatted|non-column) output for the SPELLS verb/.freeze
        
        # Pattern for parsing account name
        PlayedAccount = /^(?:<.*?\/>)?Account Info for (?<account>.+):/.freeze
        
        # Pattern for parsing subscription type
        PlayedSubscription = /Current Account Status: (?<subscription>F2P|Basic|Premium)/.freeze
        
        # Pattern for parsing last logoff time
        LastLogoff = /^\s+Logoff :  (?<weekday>[A-Z][a-z]{2}) (?<month>[A-Z][a-z]{2}) (?<day>[\s\d]{2}) (?<hour>\d{2}):(?<minute>\d{2}):(?<second>\d{2}) ET (?<year>\d{4})/.freeze
      end

      @parsing_exp_mods_output = false

      # Processes game output to check for various event triggers and updates game state
      #
      # @param server_string [String] Raw game output to parse
      # @return [String] The unmodified server string
      def self.check_events(server_string)
        Flags.matchers.each do |key, regexes|
          regexes.each do |regex|
            if (matches = server_string.match(regex))
              Flags.flags[key] = matches
              break
            end
          end
        end
        server_string
      end

      # Parses output from the 'exp mods' command to track skill modifiers
      #
      # @param server_string [String] Raw game output line to parse
      # @return [String] The unmodified server string
      # @note Updates DRSkill.exp_modifiers hash with parsed values
      def self.check_exp_mods(server_string)
        case server_string
        when %r{^<output class=""/>}
          if @parsing_exp_mods_output
            @parsing_exp_mods_output = false
          end
        else
          if @parsing_exp_mods_output
            match = /^(?<sign>[+-])(?<value>\d+)\s+(?<skill>[\w\s]+)$/.match(server_string)
            if match
              skill = match[:skill].strip
              sign = match[:sign]
              value = match[:value].to_i
              value = (value * -1) if sign == '-'
              DRSkill.update_mods(skill, value)
            end
          end
        end
        server_string
      end

      # Parses output from the 'spells' command to track known spells and feats
      #
      # @param server_string [String] Raw game output line to parse
      # @return [String] The unmodified server string
      # @note Updates DRSpells.known_spells and DRSpells.known_feats
      def self.check_known_spells(server_string)
        case server_string
        when /^<output class="mono"\/>/
          if DRSpells.grabbing_known_spells
            DRSpells.spellbook_format = 'column-formatted'
          end
        when /^[\w\s]+:/
        when /Slot\(s\): \d+ \s+ Min Prep: \d+ \s+ Max Prep: \d+/
          if DRSpells.grabbing_known_spells && DRSpells.spellbook_format == 'column-formatted'
            spell = server_string
                    .sub('<popBold/>', '')
                    .slice(10, 32)
                    .strip
            if !spell.empty?
              DRSpells.known_spells[spell] = true
            end
          end
        when /^In the chapter entitled|^You have temporarily memorized|^From your apprenticeship you remember practicing/
          if DRSpells.grabbing_known_spells
            server_string
              .sub(/^In the chapter entitled "[\w\s\'-]+", you have notes on the /, '')
              .sub(/^You have temporarily memorized the /, '')
              .sub(/^From your apprenticeship you remember practicing with the /, '')
              .sub(/ spells?\./, '')
              .sub(/,? and /, ',')
              .split(',')
              .map { |mapped_spell| mapped_spell.include?('[') ? mapped_spell.slice(0, mapped_spell.index('[')) : mapped_spell }
              .map(&:strip)
              .reject { |rejected_spell| rejected_spell.nil? || rejected_spell.empty? }
              .each { |each_spell| DRSpells.known_spells[each_spell] = true }
          end
        when /^You recall proficiency with the magic feats of/
          if DRSpells.grabbing_known_spells
            server_string
              .sub(/^You recall proficiency with the magic feats of/, '')
              .sub(/,? and /, ',')
              .sub('.', '')
              .split(',')
              .map(&:strip)
              .reject { |feat| feat.nil? || feat.empty? }
              .each { |feat| DRSpells.known_feats[feat] = true }
          end
        when /^You can use SPELL STANCE|^You have (no|yet to receive any) training in the magical arts|You have no desire to soil yourself with magical trickery|^You really shouldn't be loitering here|\(Use SPELL|\(Use PREPARE/
          DRSpells.grabbing_known_spells = false
        end
        server_string
      end

      # Parses output from Barbarian 'ability' command to track known abilities
      #
      # @param server_string [String] Raw game output line to parse
      # @return [String] The unmodified server string
      # @note Updates DRSpells.known_spells and DRSpells.known_feats
      def self.check_known_barbarian_abilities(server_string)
        case server_string
        when /^(<(push|pop)Bold\/>)?You know the (Berserks|Forms|Roars|Meditations):(<(push|pop)Bold\/>)?/
          if DRSpells.check_known_barbarian_abilities
            server_string
              .sub(/^(<(push|pop)Bold\/>)?You know the (Berserks|Forms|Roars|Meditations):(<(push|pop)Bold\/>)?/, '')
              .sub('.', '')
              .split(',')
              .map(&:strip)
              .reject { |ability| ability.nil? || ability.empty? }
              .each { |ability| DRSpells.known_spells[ability] = true }
          end
        when /^(<(push|pop)Bold\/>)?You know the (Masteries):(<(push|pop)Bold\/>)?/
          if DRSpells.check_known_barbarian_abilities
            server_string
              .sub(/^(<(push|pop)Bold\/>)?You know the (Masteries):(<(push|pop)Bold\/>)?/, '')
              .sub('.', '')
              .split(',')
              .map(&:strip)
              .reject { |mastery| mastery.nil? || mastery.empty? }
              .each { |mastery| DRSpells.known_feats[mastery] = true }
          end
        when /^You recall that you have (\d+) training sessions? remaining with the Guild/
          DRSpells.check_known_barbarian_abilities = false
        end
        server_string
      end

      # Parses output from Thief 'ability' command to track known khri abilities
      #
      # @param server_string [String] Raw game output line to parse
      # @return [String] The unmodified server string
      # @note Updates DRSpells.known_spells with khri abilities
      def self.check_known_thief_khri(server_string)
        case server_string
        when /^From the (Subtlety|Finesse|Potence) tree, you know the following khri:/
          if DRSpells.grabbing_known_khri
            server_string
              .sub(/^From the (Subtlety|Finesse|Potence) tree, you know the following khri:/, '')
              .sub('.', '')
              .gsub(/\(.+?\)/, '')
              .split(',')
              .map(&:strip)
              .reject { |ability| ability.nil? || ability.empty? }
              .each { |ability| DRSpells.known_spells[ability] = true }
          end
        when /^You have (\d+) available slots?/
          DRSpells.grabbing_known_khri = false
        end
        server_string
      end

      # Main parsing method that processes game output and updates various game states
      #
      # @param line [String] Raw game output line to parse
      # @return [Symbol, nil] :noop if no patterns matched, nil otherwise
      # @raise [StandardError] On parsing errors
      # @note Updates multiple game state objects including DRStats, DRRoom, DRSkill
      def self.parse(line)
        check_events(line)
        begin
          case line
          when Pattern::GenderAgeCircle
            DRStats.gender = Regexp.last_match[:gender]
            DRStats.age = Regexp.last_match[:age].to_i
            DRStats.circle = Regexp.last_match[:circle].to_i
          when Pattern::NameRaceGuild
            DRStats.race = Regexp.last_match[:race]
            DRStats.guild = Regexp.last_match[:guild]
          when Pattern::EncumbranceValue
            DRStats.encumbrance = Regexp.last_match[:encumbrance]
          when Pattern::LuckValue
            DRStats.luck = Regexp.last_match[:luck].to_i
          when Pattern::StatValue
            line.scan(Pattern::StatValue) do |stat, value|
              DRStats.send("#{stat.downcase}=", value.to_i)
            end
          when Pattern::TDPValue
            DRStats.tdps = Regexp.last_match(1).to_i
          when Pattern::BalanceValue
            DRStats.balance = DR_BALANCE_VALUES.index(Regexp.last_match[:balance])
          when Pattern::RoomPlayersEmpty
            DRRoom.pcs = []
          when Pattern::RoomPlayers
            DRRoom.pcs = find_pcs(Regexp.last_match(1).dup)
            DRRoom.pcs_prone = find_pcs_prone(Regexp.last_match(1).dup)
            DRRoom.pcs_sitting = find_pcs_sitting(Regexp.last_match(1).dup)
          when Pattern::RoomObjs
            DRRoom.npcs = find_npcs(Regexp.last_match(1).dup)
            UserVars.npcs = DRRoom.npcs
            DRRoom.dead_npcs = find_dead_npcs(Regexp.last_match(1).dup)
            DRRoom.room_objs = find_objects(Regexp.last_match(1).dup)
          when Pattern::RoomObjsEmpty
            DRRoom.npcs = []
            DRRoom.dead_npcs = []
            DRRoom.room_objs = []
          when Pattern::GroupMembersEmpty
            DRRoom.group_members = []
          when Pattern::GroupMembers
            DRRoom.group_members << Regexp.last_match(1)
          when Pattern::BriefExpOn, Pattern::BriefExpOff
            skill   = Regexp.last_match[:skill]
            rank    = Regexp.last_match[:rank].to_i
            rate    = Regexp.last_match[:rate].to_i > 0 ? Regexp.last_match[:rate] : DR_LEARNING_RATES.index(Regexp.last_match[:rate])
            percent = Regexp.last_match[:percent]
            DRSkill.update(skill, rank, rate, percent)
          when Pattern::ExpClearMindstate
            skill = Regexp.last_match[:skill]
            DRSkill.clear_mind(skill)
          when Pattern::ExpColumns
            line.scan(Pattern::ExpColumns) do |skill_value, rank_value, percent_value, rate_as_word|
              rate_as_number = DR_LEARNING_RATES.index(rate_as_word)
              DRSkill.update(skill_value, rank_value, rate_as_number, percent_value)
            end
          when Pattern::ExpModsStart
            @parsing_exp_mods_output = true
            DRSkill.exp_modifiers.clear
          when Pattern::SpellBookFormat
            DRSpells.spellbook_format = Regexp.last_match[:format]
          when Pattern::KnownSpellsStart
            DRSpells.grabbing_known_spells = true
            DRSpells.known_spells.clear()
            DRSpells.known_feats.clear()
            DRSpells.spellbook_format = 'non-column'
          when Pattern::BarbarianAbilitiesStart
            DRSpells.check_known_barbarian_abilities = true
            DRSpells.known_spells.clear()
            DRSpells.known_feats.clear()
          when Pattern::ThiefKhriStart
            DRSpells.grabbing_known_khri = true
            DRSpells.known_spells.clear()
            DRSpells.known_feats.clear()
          when Pattern::PlayedAccount
            if Account.name.nil?
              Account.name = Regexp.last_match[:account].upcase
            end
          when Pattern::PlayedSubscription
            if Account.subscription.nil?
              Account.subscription = Regexp.last_match[:subscription].gsub('Basic', 'Normal').gsub('F2P', 'Free').upcase
            end
            if Account.subscription == 'PREMIUM' || XMLData.game == 'DRF'
              UserVars.premium = true
            else
              UserVars.premium = false
            end
          when Pattern::LastLogoff
            matches = Regexp.last_match
            month = Date::ABBR_MONTHNAMES.find_index(matches[:month])
            weekdays = [nil, 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            dst_check = matches[:day].to_i - weekdays.find_index(matches[:weekday])
            if month.between?(4, 10) || (month == 3 && dst_check >= 7) || (month == 11 && dst_check < 0)
              tz = '-0400'
            else
              tz = '-0500'
            end
            $last_logoff = Time.new(matches[:year].to_i, month, matches[:day].to_i, matches[:hour].to_i, matches[:minute].to_i, matches[:second].to_i, tz).getlocal
          else
            :noop
          end

          check_exp_mods(line) if @parsing_exp_mods_output
          check_known_barbarian_abilities(line) if DRSpells.check_known_barbarian_abilities
          check_known_thief_khri(line) if DRSpells.grabbing_known_khri
          check_known_spells(line) if DRSpells.grabbing_known_spells
        rescue StandardError
          respond "--- Lich: error: DRParser.parse: #{$!}"
          respond "--- Lich: error: line: #{line}"
          Lich.log "error: DRParser.parse: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
          Lich.log "error: line: #{line}\n\t"
        end
      end
    end
  end
end