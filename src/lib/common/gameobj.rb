module Lich
  module Common
    # Represents a game object in the Lich game.
    class GameObj
      @@loot          = Array.new
      @@npcs          = Array.new
      @@npc_status    = Hash.new
      @@pcs           = Array.new
      @@pc_status     = Hash.new
      @@inv           = Array.new
      @@contents      = Hash.new
      @@right_hand    = nil
      @@left_hand     = nil
      @@room_desc     = Array.new
      @@fam_loot      = Array.new
      @@fam_npcs      = Array.new
      @@fam_pcs       = Array.new
      @@fam_room_desc = Array.new
      @@type_data     = Hash.new
      @@type_cache    = Hash.new
      @@sellable_data = Hash.new

      attr_reader :id
      attr_accessor :noun, :name, :before_name, :after_name

      # Initializes a new GameObj instance.
      #
      # @param id [Integer] the unique identifier for the game object
      # @param noun [String] the noun representing the game object
      # @param name [String] the name of the game object
      # @param before [String, nil] optional prefix for the name
      # @param after [String, nil] optional suffix for the name
      def initialize(id, noun, name, before = nil, after = nil)
        @id = id
        @noun = noun
        @noun = 'lapis' if @noun == 'lapis lazuli'
        @noun = 'hammer' if @noun == "Hammer of Kai"
        @noun = 'ball' if @noun == "ball and chain" # DR item 'ball and chain' doesn't work.
        @noun = 'mother-of-pearl' if (@noun == 'pearl') and (@name =~ /mother\-of\-pearl/)
        @name = name
        @before_name = before
        @after_name = after
      end

      # Determines the type of the game object based on its name and noun.
      #
      # @return [String, nil] a comma-separated list of types or nil if none found
      # @note This method will load type data if it is empty.
      # @example
      #   game_obj.type
      def type
        GameObj.load_data if @@type_data.empty?
        return @@type_cache[@name] if @@type_cache.key?(@name)
        list = @@type_data.keys.find_all { |t| (@name =~ @@type_data[t][:name] or @noun =~ @@type_data[t][:noun]) and (@@type_data[t][:exclude].nil? or @name !~ @@type_data[t][:exclude]) }
        if list.empty?
          return @@type_cache[@name] = nil
        else
          return @@type_cache[@name] = list.join(',')
        end
      end

      # Checks if the game object is sellable.
      #
      # @return [String, nil] a comma-separated list of sellable types or nil if none found
      # @note This method will load sellable data if it is empty.
      # @example
      #   game_obj.sellable
      def sellable
        GameObj.load_data if @@sellable_data.empty?
        list = @@sellable_data.keys.find_all { |t| (@name =~ @@sellable_data[t][:name] or @noun =~ @@sellable_data[t][:noun]) and (@@sellable_data[t][:exclude].nil? or @name !~ @@sellable_data[t][:exclude]) }
        if list.empty?
          nil
        else
          list.join(',')
        end
      end

      # Retrieves the status of the game object.
      #
      # @return [String, nil] the status of the object or 'gone' if not found
      # @example
      #   game_obj.status
      def status
        if @@npc_status.keys.include?(@id)
          @@npc_status[@id]
        elsif @@pc_status.keys.include?(@id)
          @@pc_status[@id]
        elsif @@loot.find { |obj| obj.id == @id } or @@inv.find { |obj| obj.id == @id } or @@room_desc.find { |obj| obj.id == @id } or @@fam_loot.find { |obj| obj.id == @id } or @@fam_npcs.find { |obj| obj.id == @id } or @@fam_pcs.find { |obj| obj.id == @id } or @@fam_room_desc.find { |obj| obj.id == @id } or (@@right_hand.id == @id) or (@@left_hand.id == @id) or @@contents.values.find { |list| list.find { |obj| obj.id == @id } }
          nil
        else
          'gone'
        end
      end

      # Sets the status of the game object.
      #
      # @param val [String] the status to set
      # @return [nil] returns nil if the object is not an NPC or PC
      # @example
      #   game_obj.status = 'active'
      def status=(val)
        if @@npcs.any? { |npc| npc.id == @id }
          @@npc_status[@id] = val
        elsif @@pcs.any? { |pc| pc.id == @id }
          @@pc_status[@id] = val
        else
          nil
        end
      end

      # Returns the noun of the game object.
      #
      # @return [String] the noun of the game object
      # @example
      #   game_obj.to_s
      def to_s
        @noun
      end

      # Checks if the game object is empty.
      #
      # @return [Boolean] always returns false
      # @example
      #   game_obj.empty?
      def empty?
        false
      end

      # Retrieves the contents of the game object.
      #
      # @return [Array] a duplicate of the contents array
      # @example
      #   game_obj.contents
      def contents
        @@contents[@id].dup
      end

      # Retrieves a game object by its identifier, noun, or name.
      #
      # @param val [String, Regexp] the identifier, noun, or name to search for
      # @return [GameObj, nil] the found game object or nil if not found
      # @example
      #   GameObj['some_id']
      def GameObj.[](val)
        if val.class == String
          if val =~ /^\-?[0-9]+$/
            @@inv.find { |o| o.id == val } || @@loot.find { |o| o.id == val } || @@npcs.find { |o| o.id == val } || @@pcs.find { |o| o.id == val } || [@@right_hand, @@left_hand].find { |o| o.id == val } || @@room_desc.find { |o| o.id == val }
          elsif val.split(' ').length == 1
            @@inv.find { |o| o.noun == val } || @@loot.find { |o| o.noun == val } || @@npcs.find { |o| o.noun == val } || @@pcs.find { |o| o.noun == val } || [@@right_hand, @@left_hand].find { |o| o.noun == val } || @@room_desc.find { |o| o.noun == val }
          else
            @@inv.find { |o| o.name == val } || @@loot.find { |o| o.name == val } || @@npcs.find { |o| o.name == val } || @@pcs.find { |o| o.name == val } || [@@right_hand, @@left_hand].find { |o| o.name == val } || @@room_desc.find { |o| o.name == val } || @@inv.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@loot.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@npcs.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@pcs.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || [@@right_hand, @@left_hand].find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@room_desc.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@inv.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@loot.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@npcs.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@pcs.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || [@@right_hand, @@left_hand].find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@room_desc.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i }
          end
        elsif val.class == Regexp
          @@inv.find { |o| o.name =~ val } || @@loot.find { |o| o.name =~ val } || @@npcs.find { |o| o.name =~ val } || @@pcs.find { |o| o.name =~ val } || [@@right_hand, @@left_hand].find { |o| o.name =~ val } || @@room_desc.find { |o| o.name =~ val }
        end
      end

      # Returns the noun of the game object.
      #
      # @return [String] the noun of the game object
      # @example
      #   game_obj.GameObj
      def GameObj
        @noun
      end

      # Constructs the full name of the game object.
      #
      # @return [String] the full name including before and after names
      # @example
      #   game_obj.full_name
      def full_name
        "#{@before_name}#{' ' unless @before_name.nil? or @before_name.empty?}#{name}#{' ' unless @after_name.nil? or @after_name.empty?}#{@after_name}"
      end

      # Creates a new NPC game object.
      #
      # @param id [Integer] the unique identifier for the NPC
      # @param noun [String] the noun representing the NPC
      # @param name [String] the name of the NPC
      # @param status [String, nil] optional status for the NPC
      # @return [GameObj] the newly created NPC object
      # @example
      #   GameObj.new_npc(1, 'goblin', 'Goblin', 'hostile')
      def GameObj.new_npc(id, noun, name, status = nil)
        obj = GameObj.new(id, noun, name)
        @@npcs.push(obj)
        @@npc_status[id] = status
        obj
      end

      # Creates a new loot game object.
      #
      # @param id [Integer] the unique identifier for the loot
      # @param noun [String] the noun representing the loot
      # @param name [String] the name of the loot
      # @return [GameObj] the newly created loot object
      # @example
      #   GameObj.new_loot(2, 'gold coin', 'Gold Coin')
      def GameObj.new_loot(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@loot.push(obj)
        obj
      end

      # Creates a new PC game object.
      #
      # @param id [Integer] the unique identifier for the PC
      # @param noun [String] the noun representing the PC
      # @param name [String] the name of the PC
      # @param status [String, nil] optional status for the PC
      # @return [GameObj] the newly created PC object
      # @example
      #   GameObj.new_pc(3, 'warrior', 'Warrior', 'active')
      def GameObj.new_pc(id, noun, name, status = nil)
        obj = GameObj.new(id, noun, name)
        @@pcs.push(obj)
        @@pc_status[id] = status
        obj
      end

      # Creates a new inventory game object.
      #
      # @param id [Integer] the unique identifier for the inventory item
      # @param noun [String] the noun representing the inventory item
      # @param name [String] the name of the inventory item
      # @param container [Integer, nil] optional container ID for the item
      # @param before [String, nil] optional prefix for the name
      # @param after [String, nil] optional suffix for the name
      # @return [GameObj] the newly created inventory object
      # @example
      #   GameObj.new_inv(4, 'potion', 'Health Potion')
      def GameObj.new_inv(id, noun, name, container = nil, before = nil, after = nil)
        obj = GameObj.new(id, noun, name, before, after)
        if container
          @@contents[container].push(obj)
        else
          @@inv.push(obj)
        end
        obj
      end

      # Creates a new room description game object.
      #
      # @param id [Integer] the unique identifier for the room description
      # @param noun [String] the noun representing the room description
      # @param name [String] the name of the room description
      # @return [GameObj] the newly created room description object
      # @example
      #   GameObj.new_room_desc(5, 'dark room', 'Dark Room')
      def GameObj.new_room_desc(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@room_desc.push(obj)
        obj
      end

      # Creates a new family room description game object.
      #
      # @param id [Integer] the unique identifier for the family room description
      # @param noun [String] the noun representing the family room description
      # @param name [String] the name of the family room description
      # @return [GameObj] the newly created family room description object
      # @example
      #   GameObj.new_fam_room_desc(6, 'family room', 'Family Room')
      def GameObj.new_fam_room_desc(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@fam_room_desc.push(obj)
        obj
      end

      # Creates a new family loot game object.
      #
      # @param id [Integer] the unique identifier for the family loot
      # @param noun [String] the noun representing the family loot
      # @param name [String] the name of the family loot
      # @return [GameObj] the newly created family loot object
      # @example
      #   GameObj.new_fam_loot(7, 'treasure chest', 'Treasure Chest')
      def GameObj.new_fam_loot(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@fam_loot.push(obj)
        obj
      end

      # Creates a new family NPC game object.
      #
      # @param id [Integer] the unique identifier for the family NPC
      # @param noun [String] the noun representing the family NPC
      # @param name [String] the name of the family NPC
      # @return [GameObj] the newly created family NPC object
      # @example
      #   GameObj.new_fam_npc(8, 'elf', 'Elf')
      def GameObj.new_fam_npc(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@fam_npcs.push(obj)
        obj
      end

      # Creates a new family PC game object.
      #
      # @param id [Integer] the unique identifier for the family PC
      # @param noun [String] the noun representing the family PC
      # @param name [String] the name of the family PC
      # @return [GameObj] the newly created family PC object
      # @example
      #   GameObj.new_fam_pc(9, 'mage', 'Mage')
      def GameObj.new_fam_pc(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@fam_pcs.push(obj)
        obj
      end

      # Creates a new right hand game object.
      #
      # @param id [Integer] the unique identifier for the right hand item
      # @param noun [String] the noun representing the right hand item
      # @param name [String] the name of the right hand item
      # @return [GameObj] the newly created right hand object
      # @example
      #   GameObj.new_right_hand(10, 'sword', 'Sword')
      def GameObj.new_right_hand(id, noun, name)
        @@right_hand = GameObj.new(id, noun, name)
      end

      # Retrieves the right hand game object.
      #
      # @return [GameObj] a duplicate of the right hand object
      # @example
      #   GameObj.right_hand
      def GameObj.right_hand
        @@right_hand.dup
      end

      # Creates a new left hand game object.
      #
      # @param id [Integer] the unique identifier for the left hand item
      # @param noun [String] the noun representing the left hand item
      # @param name [String] the name of the left hand item
      # @return [GameObj] the newly created left hand object
      # @example
      #   GameObj.new_left_hand(11, 'shield', 'Shield')
      def GameObj.new_left_hand(id, noun, name)
        @@left_hand = GameObj.new(id, noun, name)
      end

      # Retrieves the left hand game object.
      #
      # @return [GameObj] a duplicate of the left hand object
      # @example
      #   GameObj.left_hand
      def GameObj.left_hand
        @@left_hand.dup
      end

      # Clears all loot from the game.
      #
      # @return [nil] returns nil after clearing
      # @example
      #   GameObj.clear_loot
      def GameObj.clear_loot
        @@loot.clear
      end

      # Clears all NPCs from the game.
      #
      # @return [nil] returns nil after clearing
      # @example
      #   GameObj.clear_npcs
      def GameObj.clear_npcs
        @@npcs.clear
        @@npc_status.clear
      end

      # Clears all non-player characters (NPCs) from the game.
      #
      # @return [void] This method does not return a value.
      # @raise [StandardError] Raises an error if the NPCs cannot be cleared.
      # @example
      #   GameObj.clear_npcs
      def GameObj.clear_npcs
        @@npcs.clear
        @@npc_status.clear
      end

      # Clears all player characters (PCs) from the game.
      #
      # @return [void] This method does not return a value.
      # @raise [StandardError] Raises an error if the PCs cannot be cleared.
      # @example
      #   GameObj.clear_pcs
      def GameObj.clear_pcs
        @@pcs.clear
        @@pc_status.clear
      end

      # Clears the inventory of the game.
      #
      # @return [void] This method does not return a value.
      # @raise [StandardError] Raises an error if the inventory cannot be cleared.
      # @example
      #   GameObj.clear_inv
      def GameObj.clear_inv
        @@inv.clear
      end

      # Clears the room description from the game.
      #
      # @return [void] This method does not return a value.
      # @raise [StandardError] Raises an error if the room description cannot be cleared.
      # @example
      #   GameObj.clear_room_desc
      def GameObj.clear_room_desc
        @@room_desc.clear
      end

      # Clears the family room description from the game.
      #
      # @return [void] This method does not return a value.
      # @raise [StandardError] Raises an error if the family room description cannot be cleared.
      # @example
      #   GameObj.clear_fam_room_desc
      def GameObj.clear_fam_room_desc
        @@fam_room_desc.clear
      end

      # Clears the family loot from the game.
      #
      # @return [void] This method does not return a value.
      # @raise [StandardError] Raises an error if the family loot cannot be cleared.
      # @example
      #   GameObj.clear_fam_loot
      def GameObj.clear_fam_loot
        @@fam_loot.clear
      end

      # Clears the family non-player characters (NPCs) from the game.
      #
      # @return [void] This method does not return a value.
      # @raise [StandardError] Raises an error if the family NPCs cannot be cleared.
      # @example
      #   GameObj.clear_fam_npcs
      def GameObj.clear_fam_npcs
        @@fam_npcs.clear
      end

      # Clears the family player characters (PCs) from the game.
      #
      # @return [void] This method does not return a value.
      # @raise [StandardError] Raises an error if the family PCs cannot be cleared.
      # @example
      #   GameObj.clear_fam_pcs
      def GameObj.clear_fam_pcs
        @@fam_pcs.clear
      end

      # Returns a duplicate of the NPCs in the game.
      #
      # @return [Array, nil] an array of NPCs if present, otherwise nil
      def GameObj.npcs
        if @@npcs.empty?
          nil
        else
          @@npcs.dup
        end
      end

      # Returns a duplicate of the loot in the game.
      #
      # @return [Array, nil] an array of loot if present, otherwise nil
      def GameObj.loot
        if @@loot.empty?
          nil
        else
          @@loot.dup
        end
      end

      # Returns a duplicate of the player characters (PCs) in the game.
      #
      # @return [Array, nil] an array of PCs if present, otherwise nil
      def GameObj.pcs
        if @@pcs.empty?
          nil
        else
          @@pcs.dup
        end
      end

      # Returns a duplicate of the inventory in the game.
      #
      # @return [Array, nil] an array of inventory items if present, otherwise nil
      def GameObj.inv
        if @@inv.empty?
          nil
        else
          @@inv.dup
        end
      end

      # Returns a duplicate of the room description.
      #
      # @return [String, nil] the room description if present, otherwise nil
      def GameObj.room_desc
        if @@room_desc.empty?
          nil
        else
          @@room_desc.dup
        end
      end

      # Returns a duplicate of the family room description.
      #
      # @return [String, nil] the family room description if present, otherwise nil
      def GameObj.fam_room_desc
        if @@fam_room_desc.empty?
          nil
        else
          @@fam_room_desc.dup
        end
      end

      # Returns a duplicate of the family loot.
      #
      # @return [Array, nil] an array of family loot if present, otherwise nil
      def GameObj.fam_loot
        if @@fam_loot.empty?
          nil
        else
          @@fam_loot.dup
        end
      end

      # Returns a duplicate of the family NPCs.
      #
      # @return [Array, nil] an array of family NPCs if present, otherwise nil
      def GameObj.fam_npcs
        if @@fam_npcs.empty?
          nil
        else
          @@fam_npcs.dup
        end
      end

      # Returns a duplicate of the family player characters (PCs).
      #
      # @return [Array, nil] an array of family PCs if present, otherwise nil
      def GameObj.fam_pcs
        if @@fam_pcs.empty?
          nil
        else
          @@fam_pcs.dup
        end
      end

      # Clears the contents of a specified container.
      #
      # @param container_id [String] the ID of the container to clear
      # @return [void]
      def GameObj.clear_container(container_id)
        @@contents[container_id] = Array.new
      end

      # Deletes a specified container from the contents.
      #
      # @param container_id [String] the ID of the container to delete
      # @return [void]
      def GameObj.delete_container(container_id)
        @@contents.delete(container_id)
      end

      # Returns a list of targets based on current target IDs.
      #
      # @return [Array] an array of valid targets
      def GameObj.targets
        a = Array.new
        XMLData.current_target_ids.each { |id|
          if (npc = @@npcs.find { |n| n.id == id })
            next if (npc.status =~ /dead|gone/i)
            next if (npc.name =~ /^animated\b/i && npc.name !~ /^animated slush/i)
            next if (npc.noun =~ /^(?:arm|appendage|claw|limb|pincer|tentacle)s?$|^(?:palpus|palpi)$/i)
            a.push(npc)
          end
        }
        a
      end

      # Returns a list of hidden targets based on current target IDs.
      #
      # @return [Array] an array of hidden target IDs
      def GameObj.hidden_targets
        a = Array.new
        XMLData.current_target_ids.each { |id|
          unless @@npcs.find { |n| n.id == id }
            a.push(id)
          end
        }
        a
      end

      # Returns the current target based on the current target ID.
      #
      # @return [Object, nil] the current target if found, otherwise nil
      def GameObj.target
        return (@@npcs + @@pcs).find { |n| n.id == XMLData.current_target_id }
      end

      # Returns a list of dead NPCs.
      #
      # @return [Array, nil] an array of dead NPCs if any, otherwise nil
      def GameObj.dead
        dead_list = Array.new
        for obj in @@npcs
          dead_list.push(obj) if obj.status == "dead"
        end
        return nil if dead_list.empty?

        return dead_list
      end

      # Returns a duplicate of the containers in the game.
      #
      # @return [Hash] a hash of container contents
      def GameObj.containers
        @@contents.dup
      end

      # Reloads the game object data from a specified file.
      #
      # @param filename [String, nil] the name of the file to load, defaults to nil
      # @return [Boolean] true if reload was successful, false otherwise
      def GameObj.reload(filename = nil)
        GameObj.load_data(filename)
      end

      # Loads game object data from a specified file.
      #
      # @param filename [String, nil] the name of the file to load, defaults to nil
      # @return [Boolean] true if load was successful, false otherwise
      # @raise [Errno::ENOENT] if the file does not exist
      # @example
      #   GameObj.load_data("path/to/file.xml")
      def GameObj.load_data(filename = nil)
        if filename.nil?
          if File.exist?("#{DATA_DIR}/gameobj-data.xml")
            filename = "#{DATA_DIR}/gameobj-data.xml"
          elsif File.exist?("#{SCRIPT_DIR}/gameobj-data.xml") # deprecated
            filename = "#{SCRIPT_DIR}/gameobj-data.xml"
          else
            filename = "#{DATA_DIR}/gameobj-data.xml"
          end
        end
        if File.exist?(filename)
          begin
            @@type_data = Hash.new
            @@sellable_data = Hash.new
            @@type_cache = Hash.new
            File.open(filename) { |file|
              doc = REXML::Document.new(file.read)
              doc.elements.each('data/type') { |e|
                if (type = e.attributes['name'])
                  @@type_data[type] = Hash.new
                  @@type_data[type][:name]    = Regexp.new(e.elements['name'].text) unless e.elements['name'].text.nil? or e.elements['name'].text.empty?
                  @@type_data[type][:noun]    = Regexp.new(e.elements['noun'].text) unless e.elements['noun'].text.nil? or e.elements['noun'].text.empty?
                  @@type_data[type][:exclude] = Regexp.new(e.elements['exclude'].text) unless e.elements['exclude'].text.nil? or e.elements['exclude'].text.empty?
                end
              }
              doc.elements.each('data/sellable') { |e|
                if (sellable = e.attributes['name'])
                  @@sellable_data[sellable] = Hash.new
                  @@sellable_data[sellable][:name]    = Regexp.new(e.elements['name'].text) unless e.elements['name'].text.nil? or e.elements['name'].text.empty?
                  @@sellable_data[sellable][:noun]    = Regexp.new(e.elements['noun'].text) unless e.elements['noun'].text.nil? or e.elements['noun'].text.empty?
                  @@sellable_data[sellable][:exclude] = Regexp.new(e.elements['exclude'].text) unless e.elements['exclude'].text.nil? or e.elements['exclude'].text.empty?
                end
              }
            }
            true
          rescue
            @@type_data = nil
            @@sellable_data = nil
            echo "error: GameObj.load_data: #{$!}"
            respond $!.backtrace[0..1]
            false
          end
        else
          @@type_data = nil
          @@sellable_data = nil
          echo "error: GameObj.load_data: file does not exist: #{filename}"
          false
        end
      end

      # Returns the type data for the game objects.
      #
      # @return [Hash, nil] the type data if present, otherwise nil
      def GameObj.type_data
        @@type_data
      end

      # Returns the type cache for the game objects.
      #
      # @return [Hash, nil] the type cache if present, otherwise nil
      def GameObj.type_cache
        @@type_cache
      end

      # Returns the sellable data for the game objects.
      #
      # @return [Hash, nil] the sellable data if present, otherwise nil
      def GameObj.sellable_data
        @@sellable_data
      end
    end

    # start deprecated stuff
    # A deprecated class that extends GameObj.
    #
    # @deprecated This class is deprecated and may be removed in future versions.
    class RoomObj < GameObj
    end
    # end deprecated stuff
  end
end
