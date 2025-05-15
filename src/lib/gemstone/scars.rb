# frozen_string_literal: true

module Lich
  module Gemstone
    # Scars class for tracking character scars
    class Scars < Gemstone::CharacterStatus # GameBase::CharacterStatus
      class << self
        # Body part accessor methods
        # XML from Simutronics drives the structure of the scar naming (eg. leftEye)
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
        # Retrieves the scar information for the body part.
        # @return [Hash, nil] The scar data for the body part or nil if not present.
        # @note Continues to use 'both' (_injury2) for now.
        # @example
        #   Scars.leftEye
        BODY_PARTS.each do |part, aliases|
          # Define the primary method
          define_method(part) do
            fix_injury_mode('both') # continue to use 'both' (_injury2) for now

            XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['scar']
          end

          # Define shorthand alias methods
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

        # Retrieves the maximum scar level for arms (left arm, right arm, left hand, right hand).
        # @return [Integer, nil] The maximum scar level for arms or nil if not present.
        # @note Continues to use 'both' (_injury2) for now.
        # @example
        #   Scars.arms
        def arms
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['scar'],
            XMLData.injuries['rightArm']['scar'],
            XMLData.injuries['leftHand']['scar'],
            XMLData.injuries['rightHand']['scar']
          ].max
        end

        # Retrieves the maximum scar level for limbs (arms and legs).
        # @return [Integer, nil] The maximum scar level for limbs or nil if not present.
        # @note Continues to use 'both' (_injury2) for now.
        # @example
        #   Scars.limbs
        def limbs
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['scar'],
            XMLData.injuries['rightArm']['scar'],
            XMLData.injuries['leftHand']['scar'],
            XMLData.injuries['rightHand']['scar'],
            XMLData.injuries['leftLeg']['scar'],
            XMLData.injuries['rightLeg']['scar']
          ].max
        end

        # Retrieves the maximum scar level for the torso (chest, abdomen, back, eyes).
        # @return [Integer, nil] The maximum scar level for the torso or nil if not present.
        # @note Continues to use 'both' (_injury2) for now.
        # @example
        #   Scars.torso
        def torso
          fix_injury_mode('both')
          [
            XMLData.injuries['rightEye']['scar'],
            XMLData.injuries['leftEye']['scar'],
            XMLData.injuries['chest']['scar'],
            XMLData.injuries['abdomen']['scar'],
            XMLData.injuries['back']['scar']
          ].max
        end

        # Helper method to get scar level for any body part.
        # @param part [Symbol] The body part to retrieve the scar level for.
        # @return [Integer, nil] The scar level for the specified body part or nil if not present.
        # @note Continues to use 'both' (_injury2) for now.
        # @example
        #   Scars.scar_level(:leftArm)
        def scar_level(part)
          fix_injury_mode('both')
          XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['scar']
        end

        # Helper method to get all scar levels for all body parts.
        # @return [Hash] A hash of all body parts and their corresponding scar levels.
        # @raise [StandardError] If there is an issue retrieving the data.
        # @example
        #   Scars.all_scars
        def all_scars
          begin
            fix_injury_mode('scar') # for this one call, we want to get actual scar level data
            result = XMLData.injuries.transform_values { |v| v['scar'] }
          ensure
            fix_injury_mode('both') # reset to both
          end
          return result
        end
      end
    end
  end
end
