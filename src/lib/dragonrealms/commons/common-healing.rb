module Lich
  module DragonRealms
    # Module for handling healing and health-related functionality in DragonRealms
    # Provides methods for checking health status, managing wounds, and healing activities
    #
    # @author Lich5 Documentation Generator
    module DRCH
      module_function

      # Checks if there are any wounds that can be tended
      #
      # @return [Boolean] true if there are tendable wounds, false otherwise
      # @example
      #   DRCH.has_tendable_bleeders? #=> true
      def has_tendable_bleeders?
        health_data = check_health
        return true if health_data['bleeders'].values.flatten.any? { |wound| wound.tendable? }

        return false
      end

      # Checks character's health status using the HEALTH command
      #
      # @return [Hash] Health status information containing:
      #   - wounds: [Hash<Integer, Array<Wound>>] Wounds grouped by severity
      #   - bleeders: [Hash<Integer, Array<Wound>>] Bleeding wounds grouped by severity  
      #   - parasites: [Hash<Integer, Array<Wound>>] Parasites grouped by severity
      #   - lodged: [Hash<Integer, Array<Wound>>] Lodged items grouped by severity
      #   - poisoned: [Boolean] Whether character is poisoned
      #   - diseased: [Boolean] Whether character has disease/infection
      #   - score: [Integer] Calculated wound severity score
      # @example
      #   health = DRCH.check_health
      #   if health['poisoned']
      #     # Handle poison
      #   end
      def check_health
        parasites_regex = Regexp.union($DRCH_PARASITES_REGEX_LIST)
        wounds_line = nil
        parasites_line = nil
        lodged_line = nil
        diseased = false
        poisoned = false

        DRC.bput('health', 'You have', 'You feel somewhat tired and seem to be having trouble breathing', 'Your wounds', 'Your body')
        pause 0.5
        health_lines = reget(50).map(&:strip).reverse

        health_lines.each do |line|
          case line
          when /^Your body feels\b.*(?:strength|battered|beat up|bad shape|death's door|dead)/
            break
          when /Your spirit feels\b.*(?:mighty and unconquerable|full of life|strong|wavering slightly|shaky|weak|cold|empty|lifeless|dead)/
            next
          when /^You have (?!no significant injuries)(?!.* lodged .* in(?:to)? your)(?!.* infection)(?!.* poison(?:ed)?)(?!.* #{parasites_regex})/
            wounds_line = line
          when /^You have .* lodged .* in(?:to)? your/
            lodged_line = line
          when /^You have a .* on your/, parasites_regex
            parasites_line = line
          when /^You have a dormant infection/, /^Your wounds are infected/, /^Your body is covered in open oozing sores/
            diseased = true
          when /^You have .* poison(?:ed)?/, /^You feel somewhat tired and seem to be having trouble breathing/
            poisoned = true
          end
        end

        bleeders = parse_bleeders(health_lines)
        wounds = parse_wounds(wounds_line)
        parasites = parse_parasites(parasites_line)
        lodged_items = parse_lodged_items(lodged_line)
        score = calculate_score(wounds)

        return {
          'wounds'    => wounds,
          'bleeders'  => bleeders,
          'parasites' => parasites,
          'lodged'    => lodged_items,
          'poisoned'  => poisoned,
          'diseased'  => diseased,
          'score'     => score
        }
      end

      # Uses PERCEIVE HEALTH SELF command to check wounds and scars (Empath only)
      #
      # @return [Hash, nil] Same structure as check_health() if successful, nil if not an Empath
      # @note Only works for Empath characters
      # @example
      #   if DRStats.empath?
      #     health = DRCH.perceive_health
      #   end
      def perceive_health
        return unless DRStats.empath?

        case DRC.bput('perceive health self', 'feel only an aching emptiness', 'Roundtime')
        when 'feel only an aching emptiness'
          return check_health
        end

        perceived_health_data = parse_perceived_health

        health_data = check_health
        health_data['wounds'] = perceived_health_data['wounds']
        health_data['score'] = perceived_health_data['score']

        waitrt?
        return health_data
      end

      # Perceives health status of another character (Empath only)
      #
      # @param target [String] Name of character to examine
      # @return [Hash, nil] Health status of target or nil if unable to touch/examine
      # @note Only works for Empath characters
      # @example
      #   health = DRCH.perceive_health_other("Bob")
      def perceive_health_other(target)
        return unless DRStats.empath?

        case DRC.bput("touch #{target}", 'Touch what', 'feels cold and you are unable to sense anything', 'avoids your touch', 'You sense a successful empathic link has been forged between you and (?<name>\w+)\.', /^You quickly recoil/)
        when 'avoids your touch', 'feels cold and you are unable to sense anything', 'Touch what', /^You quickly recoil/
          return nil
        when /You sense a successful empathic link has been forged between you and (?<name>\w+)\./
          target = Regexp.last_match[:name]
        end

        return parse_perceived_health(target)
      end

      # Parses perceived health data from game output
      #
      # @param target [String, nil] Name of target being examined, nil for self
      # @return [Hash] Parsed health data including wounds, parasites, etc.
      # @note Internal method used by perceive_health methods
      def parse_perceived_health(target = nil)
        pause 0.5

        stop_line = target.nil? ? 'Your injuries include...' : "You sense a successful empathic link has been forged between you and #{target}\."
        health_lines = reget(100).map(&:strip).reverse
        if !health_lines.include?(stop_line)
          return
        end

        parasites_regex = Regexp.union($DRCH_PARASITES_REGEX_LIST)

        poisons_regex = Regexp.union([
                                       /^[\w]+ (?:has|have) a .* poison/,
                                       /having trouble breathing/,
                                       /Cyanide poison/
                                     ])

        diseases_regex = Regexp.union([
                                        /^[\w]+ wounds are (badly )?infected/,
                                        /^[\w]+ (?:has|have) a dormant infection/,
                                        /^[\w]+ (?:body|skin) is covered (?:in|with) open oozing sores/
                                      ])

        dead_regex = Regexp.union([
                                    /^(He|She) is dead/
                                  ])

        perceived_wounds = Hash.new { |h, k| h[k] = [] }
        perceived_parasites = Hash.new { |h, k| h[k] = [] }
        perceived_poison = false
        perceived_disease = false
        wound_body_part = nil
        dead = false

        health_lines
          .take_while { |line| line != stop_line }
          .reverse
          .each do |line|
            case line
            when dead_regex
              dead = true
            when diseases_regex
              perceived_disease = true
            when poisons_regex
              perceived_poison = true
            when parasites_regex
              line =~ /.* on (?:his|her|your) (?<body_part>[\w\s]*)/
              body_part = Regexp.last_match(1)
              severity = 1
              perceived_parasites[severity] << Wound.new(
                body_part: body_part,
                severity: severity
              )
            when /^Wounds to the (.+):/
              wound_body_part = Regexp.last_match(1)
              perceived_wounds[wound_body_part] = []
            when /^(Fresh|Scars) (External|Internal)/
              line =~ $DRCH_PERCEIVE_HEALTH_SEVERITY_REGEX
              severity = $DRCH_WOUND_TO_SEVERITY_MAP[Regexp.last_match[:severity]]
              is_internal = Regexp.last_match[:location] == 'Internal'
              is_scar = Regexp.last_match[:freshness] == 'Scars'
              perceived_wounds[body_part] << Wound.new(
                body_part: wound_body_part,
                severity: severity,
                is_internal: is_internal,
                is_scar: is_scar
              )
            end
          end

        wounds = Hash.new { |h, k| h[k] = [] }
        perceived_wounds.values.flatten.each do |wound|
          wounds[wound.severity] << wound
        end

        return {
          'wounds'    => wounds,
          'parasites' => perceived_parasites,
          'poisoned'  => perceived_poison,
          'diseased'  => perceived_disease,
          'dead'      => dead,
          'score'     => calculate_score(wounds)
        }
      end

      # Parses bleeding wound information from health output
      #
      # @param health_lines [Array<String>] Lines of text from HEALTH command
      # @return [Hash<Integer, Array<Wound>>] Bleeding wounds grouped by severity
      # @note Internal parsing method
      def parse_bleeders(health_lines)
        bleeders = Hash.new { |h, k| h[k] = [] }
        bleeder_line_regex = /^\b(inside\s+)?((l\.|r\.|left|right)\s+)?(head|eye|neck|chest|abdomen|back|arm|hand|leg|tail|skin)\b/
        if health_lines.grep(/^Bleeding|^\s*\bArea\s+Rate\b/).any?
          health_lines
            .drop_while { |line| !(bleeder_line_regex =~ line) }
            .take_while { |line| bleeder_line_regex =~ line }
            .each do |line|
              line =~ $DRCH_WOUND_BODY_PART_REGEX
              body_part = Regexp.last_match.names.find { |x| Regexp.last_match[x.to_sym] }
              body_part = Regexp.last_match[:part] if body_part == 'part'
              body_part = body_part.gsub('l.', 'left').gsub('r.', 'right')
              bleed_rate = /(?:head|eye|neck|chest|abdomen|back|arm|hand|leg|tail|skin)\s+(.+)/.match(line)[1]
              severity = $DRCH_BLEED_RATE_TO_SEVERITY_MAP[bleed_rate][:severity]
              is_internal = line =~ /^inside/ ? true : false
              bleeders[severity] << Wound.new(
                body_part: body_part,
                severity: severity,
                bleeding_rate: bleed_rate,
                is_internal: is_internal
              )
            end
        end
        return bleeders
      end

      # Binds/tends a specific wound
      #
      # @param body_part [String] Body part to tend ("left arm", "chest", etc)
      # @param person [String] Target person ("my" for self)
      # @return [Boolean] true if successfully tended, false if failed
      # @example
      #   DRCH.bind_wound("left arm")
      def bind_wound(body_part, person = 'my')
        tend_success = [
          /You work carefully at tending/,
          /You work carefully at binding/,
          /That area has already been tended to/,
          /That area is not bleeding/
        ]
        tend_failure = [
          /You fumble/,
          /too injured for you to do that/,
          /TEND allows for the tending of wounds/,
          /^You must have a hand free/
        ]
        tend_dislodge = [
          /^You \w+ remove (a|the|some) (.*) from/,
          /^As you reach for the clay fragment/
        ]

        result = DRC.bput("tend #{person} #{body_part}", *tend_success, *tend_failure, *tend_dislodge)
        waitrt?
        case result
        when *tend_dislodge
          DRCI.dispose_trash(Regexp.last_match(2), get_settings.worn_trashcan, get_settings.worn_trashcan_verb)
          bind_wound(body_part, person)
        when *tend_failure
          false
        else
          true
        end
      end

      # Removes bandages from a wound
      #
      # @param body_part [String] Body part to unwrap
      # @param person [String] Target person ("my" for self)
      # @return [void]
      # @example
      #   DRCH.unwrap_wound("chest")
      def unwrap_wound(body_part, person = 'my')
        DRC.bput("unwrap #{person} #{body_part}", 'You unwrap .* bandages', 'That area is not tended', 'You may undo the affects of TENDing')
        waitrt?
      end

      # Checks if character has sufficient First Aid skill to tend a wound
      #
      # @param bleed_rate [String] Bleeding severity ("light", "moderate", etc)
      # @param internal [Boolean] Whether wound is internal
      # @return [Boolean] true if skilled enough to tend
      # @example
      #   DRCH.skilled_to_tend_wound?("light") #=> true
      def skilled_to_tend_wound?(bleed_rate, internal = false)
        skill_target = internal ? :skill_to_tend_internal : :skill_to_tend
        min_skill = $DRCH_BLEED_RATE_TO_SEVERITY_MAP[bleed_rate][skill_target]
        return false if min_skill.nil?

        DRSkill.getrank('First Aid') >= min_skill
      end

      # Calculates overall wound severity score
      #
      # @param wounds_by_severity [Hash<Integer, Array<Wound>>] Wounds grouped by severity
      # @return [Integer] Calculated score based on wound count and severity
      # @example
      #   score = DRCH.calculate_score(wounds)
      def calculate_score(wounds_by_severity)
        wounds_by_severity.map { |severity, wound_list| (severity**2) * wound_list.count }.reduce(:+) || 0
      end

      # Class representing a single wound or injury
      class Wound
        # @return [String] Body part that is wounded
        attr_accessor :body_part
        
        # @return [Integer] Severity level of the wound
        attr_accessor :severity
        
        # @return [String] Current bleeding rate if applicable
        attr_accessor :bleeding_rate

        # Creates a new Wound instance
        #
        # @param body_part [String] Wounded body part
        # @param severity [Integer] Wound severity level
        # @param bleeding_rate [String, nil] Current bleeding rate
        # @param is_internal [Boolean] Whether wound is internal
        # @param is_scar [Boolean] Whether wound is a scar
        # @param is_parasite [Boolean] Whether wound is from a parasite
        # @param is_lodged_item [Boolean] Whether wound contains lodged item
        # @example
        #   wound = Wound.new(body_part: "left arm", severity: 2)
        def initialize(
          body_part: nil,
          severity: nil,
          bleeding_rate: nil,
          is_internal: false,
          is_scar: false,
          is_parasite: false,
          is_lodged_item: false
        )
          @body_part = body_part.nil? ? nil : body_part.downcase
          @severity = severity
          @bleeding_rate = bleeding_rate.nil? ? nil : bleeding_rate.downcase
          @is_internal = !!is_internal
          @is_scar = !!is_scar
          @is_parasite = !!is_parasite
          @is_lodged_item = !!is_lodged_item
        end

        # Checks if wound is currently bleeding
        #
        # @return [Boolean] true if actively bleeding
        def bleeding?
          return !@bleeding_rate.nil? && !@bleeding_rate.empty? && @bleeding_rate != '(tended)'
        end

        # Checks if wound is internal
        #
        # @return [Boolean] true if internal wound
        def internal?
          return @is_internal
        end

        # Checks if wound is a scar
        #
        # @return [Boolean] true if scar
        def scar?
          return @is_scar
        end

        # Checks if wound is from a parasite
        #
        # @return [Boolean] true if parasite
        def parasite?
          return @is_parasite
        end

        # Checks if wound has lodged item
        #
        # @return [Boolean] true if contains lodged item
        def lodged?
          return @is_lodged_item
        end

        # Checks if wound can be tended
        #
        # @return [Boolean] true if wound is tendable
        def tendable?
          return true if parasite?
          return true if lodged?
          return false if @body_part =~ /skin/
          return false if !bleeding?
          return false if @bleeding_rate =~ /tended|clotted/

          return DRCH.skilled_to_tend_wound?(@bleeding_rate, internal?)
        end

        # Gets wound location (internal/external)
        #
        # @return [String] "internal" or "external"
        def location
          internal? ? 'internal' : 'external'
        end

        # Gets wound type
        #
        # @return [String] "scar" or "wound"
        def type
          scar? ? 'scar' : 'wound'
        end
      end
    end
  end
end