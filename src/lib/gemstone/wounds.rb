# frozen_string_literal: true

module Lich
  module Gemstone
    # Wounds class for tracking character wounds
    class Wounds < Gemstone::CharacterStatus # GameBase::CharacterStatus
      class << self
        # Body part accessor methods
        # XML from Simutronics drives the structure of the wound naming (eg. leftEye)
        # The following is a hash of the body parts and shorthand aliases created for more idiomatic Ruby
        BODY_PARTS = {
          leftEye: ['leye'],
          rightEye: ['reye'],
          head: [],
          neck: [],
          back: [],
          chest: [],
          abdomen: ['abs'],
          leftArm: ['larm'],
          rightArm: ['rarm'],
          rightHand: ['rhand'],
          leftHand: ['lhand'],
          leftLeg: ['lleg'],
          rightLeg: ['rleg'],
          leftFoot: ['lfoot'],
          rightFoot: ['rfoot'],
          nsys: ['nerves']
        }.freeze

        # Define methods for each body part and its aliases
        # Retrieves the wound for the body part.
        # @return [String, nil] the wound level for the body part or nil if not present
        # @raise [StandardError] if there is an issue accessing XMLData
        # @example
        #   Wounds.leftEye
        BODY_PARTS.each do |part, aliases|
          # Define the primary method
          define_method(part) do
            fix_injury_mode('both') # continue to use 'both' (_injury2) for now

            XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['wound']
          end

          # Define alias methods
          aliases.each do |ali|
            alias_method ali, part
          end
        end

        # Alias snake_case methods for overachievers
        def left_eye; leftEye; end
        def right_eye; rightEye; end
        def left_arm; leftArm; end
        def right_arm; rightArm; end
        def left_hand; leftHand; end
        def right_hand; rightHand; end
        def left_leg; leftLeg; end
        def right_leg; rightLeg; end
        def left_foot; leftFoot; end
        def right_foot; rightFoot; end

        # Composite wound methods
        # Retrieves the maximum wound level for both arms and hands.
        # @return [String, nil] the maximum wound level for arms or nil if not present
        # @raise [StandardError] if there is an issue accessing XMLData
        # @example
        #   Wounds.arms
        def arms
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['wound'],
            XMLData.injuries['rightArm']['wound'],
            XMLData.injuries['leftHand']['wound'],
            XMLData.injuries['rightHand']['wound']
          ].max
        end

        # Retrieves the maximum wound level for all limbs.
        # @return [String, nil] the maximum wound level for limbs or nil if not present
        # @raise [StandardError] if there is an issue accessing XMLData
        # @example
        #   Wounds.limbs
        def limbs
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['wound'],
            XMLData.injuries['rightArm']['wound'],
            XMLData.injuries['leftHand']['wound'],
            XMLData.injuries['rightHand']['wound'],
            XMLData.injuries['leftLeg']['wound'],
            XMLData.injuries['rightLeg']['wound']
          ].max
        end

        # Retrieves the maximum wound level for the torso.
        # @return [String, nil] the maximum wound level for the torso or nil if not present
        # @raise [StandardError] if there is an issue accessing XMLData
        # @example
        #   Wounds.torso
        def torso
          fix_injury_mode('both')
          [
            XMLData.injuries['rightEye']['wound'],
            XMLData.injuries['leftEye']['wound'],
            XMLData.injuries['chest']['wound'],
            XMLData.injuries['abdomen']['wound'],
            XMLData.injuries['back']['wound']
          ].max
        end

        # Helper method to get wound level for any body part
        # @param part [Symbol] the body part to check
        # @return [String, nil] the wound level for the specified body part or nil if not present
        # @raise [StandardError] if there is an issue accessing XMLData
        # @example
        #   Wounds.wound_level(:leftArm)
        def wound_level(part)
          fix_injury_mode('both')
          XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['wound']
        end

        # Helper method to get all wound levels
        # @return [Hash] a hash of all body parts and their corresponding wound levels
        # @raise [StandardError] if there is an issue accessing XMLData
        # @example
        #   Wounds.all_wounds
        def all_wounds
          fix_injury_mode('both')
          XMLData.injuries.transform_values { |v| v['wound'] }
        end
      end
    end
  end
end
