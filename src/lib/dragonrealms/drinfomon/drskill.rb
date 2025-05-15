# Module namespace for the Lich game automation system
module Lich
  # Module for DragonRealms specific functionality 
  module DragonRealms
    # Manages character skills and experience tracking in DragonRealms
    #
    # @author Lich5 Documentation Generator
    class DRSkill
      @@skills_data ||= DR_SKILLS_DATA
      @@gained_skills ||= []
      @@start_time ||= Time.now
      @@list ||= []
      @@exp_modifiers ||= {}

      # @return [String] The name of the skill
      attr_reader :name
      # @return [Symbol] The skillset category this skill belongs to
      attr_reader :skillset
      # @return [Integer] The current rank in the skill
      attr_accessor :rank
      # @return [Integer] Current experience state (0-34)
      attr_accessor :exp
      # @return [Integer] Percentage progress to next rank (0-100)
      attr_accessor :percent
      # @return [Float] Current total rank including partial progress
      attr_accessor :current
      # @return [Float] Baseline rank for tracking gains
      attr_accessor :baseline

      # Creates a new skill instance
      #
      # @param name [String] The name of the skill
      # @param rank [Integer, String] The current rank in the skill
      # @param exp [Integer, String] Current experience state (0-34)
      # @param percent [Integer, String] Percentage to next rank (0-100)
      # @example
      #   DRSkill.new('Evasion', 100, 12, 45)
      def initialize(name, rank, exp, percent)
        @name = name # skill name like 'Evasion'
        @rank = rank.to_i # earned ranks in the skill
        # Skill mindstate x/34
        # Hardcode caped skills to 34/34
        @exp = rank.to_i >= 1750 ? 34 : exp.to_i
        @percent = percent.to_i # percent to next rank from 0 to 100
        @baseline = rank.to_i + (percent.to_i / 100.0)
        @current = rank.to_i + (percent.to_i / 100.0)
        @skillset = lookup_skillset(@name)
        @@list.push(self) unless @@list.find { |skill| skill.name == @name }
      end

      # Resets tracking of gained skills and timestamps
      #
      # @return [void]
      # @example
      #   DRSkill.reset
      def self.reset
        @@gained_skills = []
        @@start_time = Time.now
        @@list.each { |skill| skill.baseline = skill.current }
      end

      # Returns the time when skill tracking began
      #
      # @return [Time] When skill tracking started
      # @example
      #   start = DRSkill.start_time
      def self.start_time
        @@start_time
      end

      # Returns list of skills that gained experience
      #
      # @return [Array<Hash>] List of skills with experience gains
      # @example
      #   DRSkill.gained_skills #=> [{skill: "Evasion", change: 2}]
      def self.gained_skills
        @@gained_skills
      end

      # Calculates ranks gained since last reset
      #
      # @param val [String] Skill name to check
      # @return [Float] Number of ranks gained, rounded to 2 decimals
      # @example
      #   DRSkill.gained_exp('Evasion') #=> 1.25
      def self.gained_exp(val)
        skill = self.find_skill(val)
        if skill
          return skill.current ? (skill.current - skill.baseline).round(2) : 0.00
        end
      end

      # Processes experience changes for skill monitoring
      #
      # @param name [String] Skill name
      # @param new_exp [Integer] New experience value
      # @return [void]
      # @note Only triggers if UserVars.echo_exp is true
      def self.handle_exp_change(name, new_exp)
        return unless UserVars.echo_exp

        old_exp = DRSkill.getxp(name)
        change = new_exp.to_i - old_exp.to_i
        if change > 0
          DRSkill.gained_skills << { skill: name, change: change }
        end
      end

      # Checks if a skill exists
      #
      # @param val [String] Skill name to check
      # @return [Boolean] True if skill exists
      # @example
      #   DRSkill.include?('Evasion') #=> true
      def self.include?(val)
        !self.find_skill(val).nil?
      end

      # Updates a skill's current values
      #
      # @param name [String] Skill name
      # @param rank [Integer] New rank value
      # @param exp [Integer] New experience value
      # @param percent [Integer] New percent value
      # @return [DRSkill] Updated or new skill object
      def self.update(name, rank, exp, percent)
        self.handle_exp_change(name, exp)
        skill = self.find_skill(name)
        if skill
          skill.rank = rank.to_i
          skill.exp = skill.rank.to_i >= 1750 ? 34 : exp.to_i
          skill.percent = percent.to_i
          skill.current = rank.to_i + (percent.to_i / 100.0)
        else
          DRSkill.new(name, rank, exp, percent)
        end
      end

      # Updates experience modifiers for a skill
      #
      # @param name [String] Skill name
      # @param rank [Integer] Modifier value
      # @return [void]
      def self.update_mods(name, rank)
        self.exp_modifiers[self.lookup_alias(name)] = rank.to_i
      end

      # Gets current experience modifiers
      #
      # @return [Hash] Current skill modifiers
      # @example
      #   DRSkill.exp_modifiers
      def self.exp_modifiers
        @@exp_modifiers
      end

      # Resets a skill's experience to 0
      #
      # @param val [String] Skill name
      # @return [void]
      # @example
      #   DRSkill.clear_mind('Evasion')
      def self.clear_mind(val)
        self.find_skill(val).exp = 0
      end

      # Gets a skill's current rank
      #
      # @param val [String] Skill name
      # @return [Integer] Current rank
      # @example
      #   DRSkill.getrank('Evasion') #=> 100
      def self.getrank(val)
        self.find_skill(val).rank.to_i
      end

      # Gets a skill's rank with modifiers applied
      #
      # @param val [String] Skill name
      # @return [Integer] Modified rank value
      # @example
      #   DRSkill.getmodrank('Evasion') #=> 105
      def self.getmodrank(val)
        skill = self.find_skill(val)
        if skill
          rank = skill.rank.to_i
          modifier = self.exp_modifiers[skill.name].to_i
          rank + modifier
        end
      end

      # Gets a skill's current experience
      #
      # @param val [String] Skill name
      # @return [Integer] Current experience (0-34)
      # @example
      #   DRSkill.getxp('Evasion') #=> 12
      def self.getxp(val)
        skill = self.find_skill(val)
        skill.exp.to_i
      end

      # Gets percentage progress to next rank
      #
      # @param val [String] Skill name
      # @return [Integer] Percentage (0-100)
      # @example
      #   DRSkill.getpercent('Evasion') #=> 45
      def self.getpercent(val)
        self.find_skill(val).percent.to_i
      end

      # Gets the skillset category for a skill
      #
      # @param val [String] Skill name
      # @return [Symbol] Skillset category
      # @example
      #   DRSkill.getskillset('Evasion') #=> :combat
      def self.getskillset(val)
        self.find_skill(val).skillset
      end

      # Displays all skills and their current status
      #
      # @return [void]
      # @example
      #   DRSkill.listall
      def self.listall
        @@list.each do |i|
          echo "#{i.name}: #{i.rank}.#{i.percent}% [#{i.exp}/34]"
        end
      end

      # Gets list of all skills
      #
      # @return [Array<DRSkill>] List of all skill objects
      # @example
      #   DRSkill.list
      def self.list
        @@list
      end

      # Finds a skill object by name
      #
      # @param val [String] Skill name
      # @return [DRSkill, nil] Skill object or nil if not found
      # @example
      #   DRSkill.find_skill('Evasion')
      def self.find_skill(val)
        @@list.find { |data| data.name == self.lookup_alias(val) }
      end

      # Converts guild-specific skill names to canonical names
      #
      # @param skill [String] Skill name to lookup
      # @return [String] Canonical skill name
      # @example
      #   DRSkill.lookup_alias('Inner Fire') #=> 'Primary Magic'
      # @note Handles guild-specific skill name variations
      def self.lookup_alias(skill)
        @@skills_data[:guild_skill_aliases][DRStats.guild][skill] || skill
      end

      # Determines which skillset a skill belongs to
      #
      # @param skill [String] Skill name
      # @return [Symbol] Skillset category
      # @example
      #   lookup_skillset('Evasion') #=> :combat
      # @note Instance method used during initialization
      def lookup_skillset(skill)
        @@skills_data[:skillsets].find { |_skillset, skills| skills.include?(skill) }.first
      end
    end
  end
end