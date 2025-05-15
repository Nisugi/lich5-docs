# frozen_string_literal: true

# Module for handling game line parsing and information monitoring in the Lich system
module Lich
  module Gemstone
    module Infomon
      # Handles parsing of game text lines to extract and update character information
      # @note This module contains pattern matching and state tracking for parsing game output
      module Parser
        # Contains all regex patterns used for parsing game text
        # @note These patterns are used to match and extract information from game lines
        module Pattern
          # @!attribute [r] CharRaceProf
          # @return [Regexp] Matches character name, race and profession
          CharRaceProf = /^Name:\s+(?<name>[A-z\s'-]+)\s+Race:\s+(?<race>[A-z]+|[A-z]+(?: |-)[A-z]+)\s+Profession:\s+(?<profession>[-A-z]+)/.freeze

          # @!attribute [r] CharGenderAgeExpLevel
          # @return [Regexp] Matches character gender, age, experience and level
          CharGenderAgeExpLevel = /^Gender:\s+(?<gender>[A-z]+)\s+Age:\s+(?<age>[,0-9]+)\s+Expr:\s+(?<experience>[0-9,]+)\s+Level:\s+(?<level>[0-9]+)/.freeze

          # @!attribute [r] Stat
          # @return [Regexp] Matches character stats and bonuses
          Stat = /^\s*(?<stat>[A-z]+)\s\((?:STR|CON|DEX|AGI|DIS|AUR|LOG|INT|WIS|INF)\):\s+(?<value>[0-9]+)\s\((?<bonus>-?[0-9]+)\)\s+[.]{3}\s+(?<enhanced_value>\d+)\s+\((?<enhanced_bonus>-?\d+)\)/.freeze

          # Additional pattern constants...
          # [Rest of pattern constants remain unchanged]

          # @!attribute [r] All
          # @return [Regexp] Union of all parsing patterns
          All = Regexp.union(CharRaceProf, CharGenderAgeExpLevel, Stat, StatEnd, Fame, RealExp, AscExp, TotalExp, LTE,
                           ExprEnd, SkillStart, Skill, SpellRanks, SkillEnd, PSMStart, PSM, PSMEnd, Levelup, SpellsSolo,
                           Citizenship, NoCitizenship, Society, NoSociety, SleepActive, SleepNoActive, BindActive,
                           BindNoActive, SilenceActive, SilenceNoActive, CalmActive, CalmNoActive, CutthroatActive,
                           CutthroatNoActive, SpellUpMsgs, SpellDnMsgs, Warcries, NoWarcries, SocietyJoin, SocietyStep,
                           SocietyResign, LearnPSM, UnlearnPSM, LostTechnique, LearnTechnique, UnlearnTechnique,
                           Resource, Suffused, VolnFavor, GigasArtifactFragments, RedsteelMarks, TicketGeneral,
                           TicketBlackscrip, TicketBloodscrip, TicketEtherealScrip, TicketSoulShards, TicketRaikhen,
                           WealthSilver, WealthSilverContainer, GoalsDetected, GoalsEnded, SpellsongRenewed,
                           ThornPoisonStart, ThornPoisonProgression, ThornPoisonDeprogression, ThornPoisonEnd, CovertArtsCharges,
                           AccountName, AccountSubscription, ProfileStart, ProfileName, ProfileHouseCHE, ResignCHE, GemstoneDust)
        end

        # Tracks the current parsing state
        # @note Used to handle multi-line parsing scenarios
        module State
          @state = :ready
          Goals = :goals
          Profile = :profile
          Ready = :ready

          # Sets the parser state
          # @param state [Symbol] New state to set
          # @raise [RuntimeError] If attempting invalid state transition
          # @return [Symbol] The new state
          def self.set(state)
            case state
            when Goals, Profile
              unless @state.eql?(Ready)
                Lich.log "error: Infomon::Parser::State is in invalid state(#{@state}) - caller: #{caller[0]}"
                fail "--- Lich: error: Infomon::Parser::State is in invalid state(#{@state}) - caller: #{caller[0]}"
              end
            end
            @state = state
          end

          # Gets the current parser state
          # @return [Symbol] Current state
          def self.get
            @state
          end
        end

        # Determines the category for a PSM (Professional Skill/Maneuver)
        # @param category [String] Raw category text from game
        # @return [String] Normalized category name ('Armor', 'Ascension', 'CMan', etc)
        def self.find_cat(category)
          case category
          when /Armor/
            'Armor'
          when /Ascension/
            'Ascension'
          when /Combat/
            'CMan'
          when /Feat/
            'Feat'
          when /Shield/
            'Shield'
          when /Weapon/
            'Weapon'
          end
        end

        # Main parsing method that processes game text lines
        # @param line [String] Raw game text line to parse
        # @return [Symbol] :ok if line was processed, :noop if line didn't match any patterns
        # @raise [StandardError] On parsing errors
        def self.parse(line)
          # O(1) vs O(N)
          return :noop unless line =~ Pattern::All

          begin
            case line
            # [Rest of parse method implementation remains unchanged]
            end
          rescue StandardError
            respond "--- Lich: error: Infomon::Parser.parse: #{$!}"
            respond "--- Lich: error: line: #{line}"
            Lich.log "error: Infomon::Parser.parse: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
            Lich.log "error: line: #{line}\n\t"
          end
        end
      end
    end
  end
end