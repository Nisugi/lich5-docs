# frozen_string_literal: true

# Module namespace for the Lich application
module Lich

  # Module namespace for Gemstone-specific functionality 
  module Gemstone

    # Tracks and manages character wound states across different body parts
    # Inherits from Gemstone::CharacterStatus
    #
    # @author Lich5 Documentation Generator
    class Wounds < Gemstone::CharacterStatus # GameBase::CharacterStatus
      class << self
        # Hash mapping body part names to their shorthand aliases
        # The keys are the official XML names from Simutronics, values are arrays of aliases
        #
        # @return [Hash<Symbol, Array<String>>] Mapping of body parts to aliases
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

        # Gets the wound level for the left eye
        # @return [Integer] Wound level from 0-3
        def left_eye; leftEye; end

        # Gets the wound level for the right eye
        # @return [Integer] Wound level from 0-3
        def right_eye; rightEye; end

        # Gets the wound level for the left arm
        # @return [Integer] Wound level from 0-3
        def left_arm; leftArm; end

        # Gets the wound level for the right arm
        # @return [Integer] Wound level from 0-3
        def right_arm; rightArm; end

        # Gets the wound level for the left hand
        # @return [Integer] Wound level from 0-3
        def left_hand; leftHand; end

        # Gets the wound level for the right hand
        # @return [Integer] Wound level from 0-3
        def right_hand; rightHand; end

        # Gets the wound level for the left leg
        # @return [Integer] Wound level from 0-3
        def left_leg; leftLeg; end

        # Gets the wound level for the right leg
        # @return [Integer] Wound level from 0-3
        def right_leg; rightLeg; end

        # Gets the wound level for the left foot
        # @return [Integer] Wound level from 0-3
        def left_foot; leftFoot; end

        # Gets the wound level for the right foot
        # @return [Integer] Wound level from 0-3
        def right_foot; rightFoot; end

        # Gets the combined wound level for both arms and hands
        #
        # @return [Integer] Maximum wound level among all arm parts
        # @example
        #   Wounds.arms #=> 3
        def arms
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['wound'],
            XMLData.injuries['rightArm']['wound'],
            XMLData.injuries['leftHand']['wound'],
            XMLData.injuries['rightHand']['wound']
          ].max
        end

        # Gets the combined wound level for all limbs (arms, hands, legs)
        #
        # @return [Integer] Maximum wound level among all limb parts
        # @example
        #   Wounds.limbs #=> 2
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

        # Gets the combined wound level for torso area (eyes, chest, abdomen, back)
        #
        # @return [Integer] Maximum wound level among all torso parts
        # @example
        #   Wounds.torso #=> 1
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

        # Gets the wound level for any specified body part
        #
        # @param part [String, Symbol] The body part name
        # @return [Integer, nil] Wound level from 0-3, or nil if invalid part
        # @example
        #   Wounds.wound_level('head') #=> 2
        #   Wounds.wound_level(:leftArm) #=> 1
        def wound_level(part)
          fix_injury_mode('both')
          XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['wound']
        end

        # Gets a hash of all body parts and their current wound levels
        #
        # @return [Hash<String, Integer>] Mapping of body part names to wound levels
        # @example
        #   Wounds.all_wounds #=> {'head' => 0, 'neck' => 1, ...}
        def all_wounds
          fix_injury_mode('both')
          XMLData.injuries.transform_values { |v| v['wound'] }
        end
      end

      # @note All wound level methods return integers 0-3 representing:
      #   0 = No wounds
      #   1 = Light wounds
      #   2 = Moderate wounds
      #   3 = Severe wounds
      #
      # @note All methods rely on XMLData.injuries being properly populated
      #   from the game's XML data stream
      #
      # @note The fix_injury_mode('both') call ensures proper data mode
      #   is set before accessing wound data
    end
  end
end