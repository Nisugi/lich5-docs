# A module containing Gemstone game-specific functionality
#
# @author Lich5 Documentation Generator
module Lich

  # Contains Gemstone-specific game mechanics and systems 
  module Gemstone

    # Defines critical hit tables and rankings for the combat system
    # This module handles generic critical hits that are not specific to a particular
    # location or type of damage.
    #
    # Generic crits represent universal effects that can apply to any target,
    # regardless of their anatomy or damage type. For example, a stunning effect
    # that works on any creature even if they lack the specific body part targeted.
    #
    # @note Generic crits use a standardized format with required fields for damage,
    #   effects, and matching regex patterns
    #
    # @example Critical Table Structure
    #   GENERIC:
    #     UNSPECIFIED:
    #       0:
    #         type: GENERIC
    #         location: UNSPECIFIED
    #         rank: 0
    #         # ... additional attributes
    #
    # @attribute [r] table
    #   @return [Hash] The complete critical hit table definitions
    #
    # @note Critical table entries must include:
    #   - :type - Must match the table name
    #   - :location - Body location affected
    #   - :rank - Severity ranking
    #   - :damage - Additional damage dealt
    #   - :position - Forced position changes
    #   - :fatal - Whether crit causes death
    #   - :stunned - Rounds of stun (999 for unknown)
    #   - :amputated - Whether location is severed
    #   - :crippled - Whether location becomes unusable
    #   - :sleeping - Whether target falls unconscious
    #   - :dazed - Mental effect status
    #   - :limb_favored - Limb favor status
    #   - :roundtime - Additional action delay
    #   - :silenced - Speaking/casting prevention
    #   - :slowed - Movement speed reduction
    #   - :wound_rank - Severity of wound
    #   - :secondary_wound - Additional wound location
    #   - :regex - Pattern matching the crit message
    #
    # @note As of 2025/03/14, regex patterns use standardized /^String format
    #   and consistent .*? patterns for XML parsing compatibility
    module CritRanks
      CritRanks.table[:generic] =
        { :unspecified =>
                          { 0 =>
                                 { :type            => "generic",
                                   :location        => "unspecified", 
                                   :rank            => 0,
                                   :damage          => 0,
                                   :position        => nil,
                                   :fatal           => false,
                                   :stunned         => 999, # generic crits cannot have legitimate stun values (or any other value)
                                   :amputated       => false,
                                   :crippled        => false,
                                   :sleeping        => false,
                                   :wound_rank      => 0,
                                   :secondary_wound => nil,
                                   :regex           => /.*? is stunned./ } } }
    end
  end
end