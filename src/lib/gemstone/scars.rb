# frozen_string_literal: true

# Module namespace for the Lich application
module Lich
  # Module namespace for Gemstone-specific functionality 
  module Gemstone
    # Tracks and manages character scars/scarring for different body parts
    # Inherits from Gemstone::CharacterStatus
    #
    # @author Lich5 Documentation Generator
    class Scars < Gemstone::CharacterStatus # GameBase::CharacterStatus
      class << self
        # Hash mapping body part names to their shorthand aliases
        # The keys are the official XML body part names, and values are arrays of alias names
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

            XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['scar']
          end

          # Define shorthand alias methods
          aliases.each do |ali|
            alias_method ali, part
          end
        end

        # Gets the scar level for the left eye (snake_case version)
        #
        # @return [Integer, nil] Scar level from 0-3, or nil if no data
        # @example
        #   Scars.left_eye #=> 2
        def left_eye; leftEye; end

        # Gets the scar level for the right eye (snake_case version)
        #
        # @return [Integer, nil] Scar level from 0-3, or nil if no data
        # @example
        #   Scars.right_eye #=> 1
        def right_eye; rightEye; end

        # Gets the scar level for the left arm (snake_case version)
        #
        # @return [Integer, nil] Scar level from 0-3, or nil if no data
        # @example
        #   Scars.left_arm #=> 2
        def left_arm; leftArm; end

        # Gets the scar level for the right arm (snake_case version)
        #
        # @return [Integer, nil] Scar level from 0-3, or nil if no data
        # @example
        #   Scars.right_arm #=> 1
        def right_arm; rightArm; end

        # Gets the scar level for the left hand (snake_case version)
        #
        # @return [Integer, nil] Scar level from 0-3, or nil if no data
        # @example
        #   Scars.left_hand #=> 0
        def left_hand; leftHand; end

        # Gets the scar level for the right hand (snake_case version)
        #
        # @return [Integer, nil] Scar level from 0-3, or nil if no data
        # @example
        #   Scars.right_hand #=> 1
        def right_hand; rightHand; end

        # Gets the scar level for the left leg (snake_case version)
        #
        # @return [Integer, nil] Scar level from 0-3, or nil if no data
        # @example
        #   Scars.left_leg #=> 2
        def left_leg; leftLeg; end

        # Gets the scar level for the right leg (snake_case version)
        #
        # @return [Integer, nil] Scar level from 0-3, or nil if no data
        # @example
        #   Scars.right_leg #=> 1
        def right_leg; rightLeg; end

        # Gets the scar level for the left foot (snake_case version)
        #
        # @return [Integer, nil] Scar level from 0-3, or nil if no data
        # @example
        #   Scars.left_foot #=> 0
        def left_foot; leftFoot; end

        # Gets the scar level for the right foot (snake_case version)
        #
        # @return [Integer, nil] Scar level from 0-3, or nil if no data
        # @example
        #   Scars.right_foot #=> 1
        def right_foot; rightFoot; end

        # Gets the maximum scar level across all arm-related body parts
        #
        # @return [Integer] Highest scar level among arms and hands
        # @example
        #   Scars.arms #=> 3 # Returns highest scar level among all arm parts
        def arms
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['scar'],
            XMLData.injuries['rightArm']['scar'],
            XMLData.injuries['leftHand']['scar'],
            XMLData.injuries['rightHand']['scar']
          ].max
        end

        # Gets the maximum scar level across all limbs (arms and legs)
        #
        # @return [Integer] Highest scar level among all limbs
        # @example
        #   Scars.limbs #=> 2 # Returns highest scar level among all limbs
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

        # Gets the maximum scar level across torso-related body parts
        #
        # @return [Integer] Highest scar level among torso parts
        # @example
        #   Scars.torso #=> 1 # Returns highest scar level among torso parts
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

        # Gets the scar level for any specified body part
        #
        # @param part [String, Symbol] The body part name to check
        # @return [Integer, nil] Scar level from 0-3, or nil if invalid part
        # @example
        #   Scars.scar_level('leftArm') #=> 2
        #   Scars.scar_level(:head)     #=> 1
        def scar_level(part)
          fix_injury_mode('both')
          XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['scar']
        end

        # Gets a hash of all body parts and their current scar levels
        #
        # @return [Hash<String, Integer>] Mapping of body part names to scar levels
        # @note Temporarily switches to scar-only mode to get accurate data
        # @example
        #   Scars.all_scars #=> {"leftArm" => 2, "head" => 1, ...}
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