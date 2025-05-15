# Module containing DragonRealms game-specific functionality
module Lich

  # Module containing healing and wound-related data structures for DragonRealms
  # Contains mappings and regular expressions for parsing wound severity, bleeding rates,
  # lodged items, parasites and body parts.
  #
  # @author Lich5 Documentation Generator
  module DragonRealms
    # Maps bleed rates to severity data including bleeding status and required First Aid skill
    # Lower severity numbers indicate less severe wounds
    #
    # @note Partially tended wounds are considered more severe than untended ones
    # @see https://elanthipedia.play.net/Damage#Bleeding_Levels
    # @see https://elanthipedia.play.net/First_Aid_skill#Skill_to_Tend
    $DRCH_BLEED_RATE_TO_SEVERITY_MAP = {
      'tended'                   => {
        severity: 1,                  # lower numbers are less severe than higher numbers
        bleeding: false,              # is it actively bleeding and causing vitality loss?
        skill_to_tend: nil,           # ranks in First Aid needed to tend this external wound
        skill_to_tend_internal: nil   # ranks in First Aid needed to tend this internal wound
      },
      # ... rest of the bleed rate map ...
    }

    # Maps lodged item descriptions to severity numbers (1-5)
    #
    # @see https://elanthipedia.play.net/Damage#Lodged_Items 
    $DRCH_LODGED_TO_SEVERITY_MAP = {
      'loosely hanging' => 1,
      'shallowly'       => 2,
      'firmly'          => 3,
      'deeply'          => 4,
      'savagely'        => 5
    }

    # Maps wound descriptions to severity numbers (1-13)
    #
    # @see https://elanthipedia.play.net/Damage#Wound_Severity_Levels
    $DRCH_WOUND_TO_SEVERITY_MAP = {
      'insignificant'    => 1,
      'negligible'       => 2,
      'minor'            => 3,
      'more than minor'  => 4,
      'harmful'          => 5,
      'very harmful'     => 6,
      'damaging'         => 7,
      'very damaging'    => 8,
      'severe'           => 9,
      'very severe'      => 10,
      'devastating'      => 11,
      'very devastating' => 12,
      'useless'          => 13
    }

    # Regular expressions for matching different types of parasites
    #
    # @see https://elanthipedia.play.net/Damage#Parasites
    $DRCH_PARASITES_REGEX_LIST = [
      /(?:small|large) (?:black|red) blood mite/,
      /(?:black|red|albino) (sand|forest) leech/,
      /(?:green|red) blood worm/,
      /retch maggot/
    ]

    # Regex for parsing severity from 'perceive health self' output
    #
    # @example Matches "Fresh External: light scratches -- negligible"
    # @return [MatchData] Contains :freshness, :location, and :severity named captures
    $DRCH_PERCEIVE_HEALTH_SEVERITY_REGEX = /(?<freshness>Fresh|Scars) (?<location>External|Internal).+--\s+(?<severity>insignificant|negligible|minor|more than minor|harmful|very harmful|damaging|very damaging|severe|very severe|devastating|very devastating|useless)\b/

    # Basic regex for matching body part names
    #
    # @example Matches "left arm", "r. leg", etc
    # @return [MatchData] Contains :part named capture
    $DRCH_BODY_PART_REGEX = /(?<part>(?:l\.|r\.|left|right)?\s?(?:\w+))/

    # Regex for matching body parts in wound/bleeding descriptions
    #
    # @example Matches "inside left arm"
    # @return [MatchData] Contains :part named capture
    $DRCH_WOUND_BODY_PART_REGEX = /(?:inside)?\s?#{$DRCH_BODY_PART_REGEX}/

    # Regex for matching body parts with lodged items
    #
    # @example Matches "lodged deeply into your left arm"
    # @return [MatchData] Contains :part named capture
    $DRCH_LODGED_BODY_PART_REGEX = /lodged .* into your #{$DRCH_BODY_PART_REGEX}/

    # Regex for matching body parts with parasites
    #
    # @example Matches "on your right leg"
    # @return [MatchData] Contains :part named capture
    $DRCH_PARASITE_BODY_PART_REGEX = /on your #{$DRCH_BODY_PART_REGEX}/

    # Maps wound description patterns to severity data
    #
    # @see https://elanthipedia.play.net/Damage#Wounds
    # @return [Hash] Keys are regex patterns, values are hashes containing:
    #   :severity [Integer] Wound severity (1-8)
    #   :internal [Boolean] Whether wound is internal
    #   :scar [Boolean] Whether wound is scarred
    $DRCH_WOUND_SEVERITY_REGEX_MAP = {
      # ... wound severity regex map ...
    }

    # Regex for splitting wound descriptions with multiple attributes
    #
    # @example Splits "swollen, bruised and bleeding"
    $DRCH_WOUND_COMMA_SEPARATOR = /(?<=swollen|bruised|scarred|painful),(?=\s(?:swollen|bruised|mangled|inflamed))/
  end
end