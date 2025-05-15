# Module for core Lich functionality
module Lich
  # Module containing common game-related functionality 
  module Common
    # Represents game objects like items, NPCs, PCs and containers
    #
    # GameObj provides functionality for tracking and managing various types of objects
    # in the game world including inventory items, NPCs, PCs, room descriptions and more.
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

      # @return [String] The unique identifier for this game object
      attr_reader :id
      
      # @return [String] The base noun/type of this object
      # @return [String] The full name of this object
      # @return [String] Any text that appears before the object name
      # @return [String] Any text that appears after the object name
      attr_accessor :noun, :name, :before_name, :after_name

      # Creates a new game object
      #
      # @param id [String] Unique identifier
      # @param noun [String] Base noun/type
      # @param name [String] Full name
      # @param before [String, nil] Text before name
      # @param after [String, nil] Text after name
      # @return [GameObj] New game object instance
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

      # Gets the type(s) of this object based on name/noun patterns
      #
      # @return [String, nil] Comma-separated list of types or nil if no matches
      # @note Loads type data from XML if not already loaded
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

      # Checks if this object is sellable based on name/noun patterns
      #
      # @return [String, nil] Comma-separated list of sellable types or nil if not sellable
      # @note Loads sellable data from XML if not already loaded
      def sellable
        GameObj.load_data if @@sellable_data.empty?
        list = @@sellable_data.keys.find_all { |t| (@name =~ @@sellable_data[t][:name] or @noun =~ @@sellable_data[t][:noun]) and (@@sellable_data[t][:exclude].nil? or @name !~ @@sellable_data[t][:exclude]) }
        if list.empty?
          nil
        else
          list.join(',')
        end
      end

      # Gets the status of this object (dead, gone, etc)
      #
      # @return [String, nil] Status string or nil if object exists
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

      # Sets the status for NPCs and PCs
      #
      # @param val [String] New status value
      # @return [String, nil] Set status or nil if not NPC/PC
      def status=(val)
        if @@npcs.any? { |npc| npc.id == @id }
          @@npc_status[@id] = val
        elsif @@pcs.any? { |pc| pc.id == @id }
          @@pc_status[@id] = val
        else
          nil
        end
      end

      # Returns the noun of this object
      #
      # @return [String] The noun
      def to_s
        @noun
      end

      # Checks if this object is empty
      #
      # @return [Boolean] Always returns false
      def empty?
        false
      end

      # Gets contents of this container object
      # 
      # @return [Array<GameObj>] Array of contained objects
      def contents
        @@contents[@id].dup
      end

      # Finds a game object by ID, noun or name
      #
      # @param val [String, Regexp] Search value
      # @return [GameObj, nil] Matching object or nil
      def GameObj.[](val)
        unless val.is_a?(String) || val.is_a?(Regexp)
          respond "--- Lich: error: GameObj[] passed with #{val.class} #{val} via caller: #{caller[0]}"
          respond "--- Lich: error: GameObj[] supports String or Regexp only"
          Lich.log "--- Lich: error: GameObj[] passed with #{val.class} #{val} via caller: #{caller[0]}\n\t"
          Lich.log "--- Lich: error: GameObj[] supports String or Regexp only\n\t"
          if val.is_a?(Integer)
            respond "--- Lich: error: GameObj[] converted Integer #{val} to String to continue"
            val = val.to_s
          else
            return
          end
        end
        if val.is_a?(String)
          if val =~ /^\-?[0-9]+$/ # ID lookup
            # excludes @@room_desc ID lookup due to minimal use case, but could be added in future if desired
            @@inv.find { |o| o.id == val } || @@loot.find { |o| o.id == val } || @@npcs.find { |o| o.id == val } || @@pcs.find { |o| o.id == val } || [@@right_hand, @@left_hand].find { |o| o.id == val } || @@room_desc.find { |o| o.id == val } || @@contents.values.flatten.find { |o| o.id == val }
          elsif val.split(' ').length == 1 # noun lookup
            @@inv.find { |o| o.noun == val } || @@loot.find { |o| o.noun == val } || @@npcs.find { |o| o.noun == val } || @@pcs.find { |o| o.noun == val } || [@@right_hand, @@left_hand].find { |o| o.noun == val } || @@room_desc.find { |o| o.noun == val }
          else # name lookup
            @@inv.find { |o| o.name == val } || @@loot.find { |o| o.name == val } || @@npcs.find { |o| o.name == val } || @@pcs.find { |o| o.name == val } || [@@right_hand, @@left_hand].find { |o| o.name == val } || @@room_desc.find { |o| o.name == val } || @@inv.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@loot.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@npcs.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@pcs.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || [@@right_hand, @@left_hand].find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@room_desc.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@inv.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@loot.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@npcs.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@pcs.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || [@@right_hand, @@left_hand].find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@room_desc.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i }
          end
        elsif val.is_a?(Regexp) # name only lookup when passed a Regexp
          @@inv.find { |o| o.name =~ val } || @@loot.find { |o| o.name =~ val } || @@npcs.find { |o| o.name =~ val } || @@pcs.find { |o| o.name =~ val } || [@@right_hand, @@left_hand].find { |o| o.name =~ val } || @@room_desc.find { |o| o.name =~ val }
        end
      end

      def GameObj
        @noun
      end

      # Gets the full name including before/after text
      #
      # @return [String] Complete object name
      def full_name
        "#{@before_name}#{' ' unless @before_name.nil? or @before_name.empty?}#{name}#{' ' unless @after_name.nil? or @after_name.empty?}#{@after_name}"
      end

      # Creates a new NPC object
      #
      # @param id [String] Unique ID
      # @param noun [String] Base noun
      # @param name [String] Full name  
      # @param status [String, nil] Initial status
      # @return [GameObj] New NPC object
      def GameObj.new_npc(id, noun, name, status = nil)
        obj = GameObj.new(id, noun, name)
        @@npcs.push(obj)
        @@npc_status[id] = status
        obj
      end

      # Creates a new loot object
      #
      # @param id [String] Unique ID
      # @param noun [String] Base noun
      # @param name [String] Full name
      # @return [GameObj] New loot object
      def GameObj.new_loot(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@loot.push(obj)
        obj
      end

      # Creates a new PC object
      #
      # @param id [String] Unique ID
      # @param noun [String] Base noun
      # @param name [String] Full name
      # @param status [String, nil] Initial status
      # @return [GameObj] New PC object
      def GameObj.new_pc(id, noun, name, status = nil)
        obj = GameObj.new(id, noun, name)
        @@pcs.push(obj)
        @@pc_status[id] = status
        obj
      end

      # Creates a new inventory object
      #
      # @param id [String] Unique ID
      # @param noun [String] Base noun
      # @param name [String] Full name
      # @param container [String, nil] Container ID if in container
      # @param before [String, nil] Text before name
      # @param after [String, nil] Text after name
      # @return [GameObj] New inventory object
      def GameObj.new_inv(id, noun, name, container = nil, before = nil, after = nil)
        obj = GameObj.new(id, noun, name, before, after)
        if container
          @@contents[container].push(obj)
        else
          @@inv.push(obj)
        end
        obj
      end

      def GameObj.new_room_desc(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@room_desc.push(obj)
        obj
      end

      def GameObj.new_fam_room_desc(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@fam_room_desc.push(obj)
        obj
      end

      def GameObj.new_fam_loot(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@fam_loot.push(obj)
        obj
      end

      def GameObj.new_fam_npc(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@fam_npcs.push(obj)
        obj
      end

      def GameObj.new_fam_pc(id, noun, name)
        obj = GameObj.new(id, noun, name)
        @@fam_pcs.push(obj)
        obj
      end

      def GameObj.new_right_hand(id, noun, name)
        @@right_hand = GameObj.new(id, noun, name)
      end

      # Gets current right hand item
      #
      # @return [GameObj, nil] Right hand object or nil if empty
      def GameObj.right_hand
        @@right_hand.dup
      end

      def GameObj.new_left_hand(id, noun, name)
        @@left_hand = GameObj.new(id, noun, name)
      end

      # Gets current left hand item
      #
      # @return [GameObj, nil] Left hand object or nil if empty
      def GameObj.left_hand
        @@left_hand.dup
      end

      def GameObj.clear_loot
        @@loot.clear
      end

      def GameObj.clear_npcs
        @@npcs.clear
        @@npc_status.clear
      end

      def GameObj.clear_pcs
        @@pcs.clear
        @@pc_status.clear
      end

      def GameObj.clear_inv
        @@inv.clear
      end

      def GameObj.clear_room_desc
        @@room_desc.clear
      end

      def GameObj.clear_fam_room_desc
        @@fam_room_desc.clear
      end

      def GameObj.clear_fam_loot
        @@fam_loot.clear
      end

      def GameObj.clear_fam_npcs
        @@fam_npcs.clear
      end

      def GameObj.clear_fam_pcs
        @@fam_pcs.clear
      end

      def GameObj.npcs
        if @@npcs.empty?
          nil
        else
          @@npcs.dup
        end
      end

      def GameObj.loot
        if @@loot.empty?
          nil
        else
          @@loot.dup
        end
      end

      def GameObj.pcs
        if @@pcs.empty?
          nil
        else
          @@pcs.dup
        end
      end

      def GameObj.inv
        if @@inv.empty?
          nil
        else
          @@inv.dup
        end
      end

      def GameObj.room_desc
        if @@room_desc.empty?
          nil
        else
          @@room_desc.dup
        end
      end

      def GameObj.fam_room_desc
        if @@fam_room_desc.empty?
          nil
        else
          @@fam_room_desc.dup
        end
      end

      def GameObj.fam_loot
        if @@fam_loot.empty?
          nil
        else
          @@fam_loot.dup
        end
      end

      def GameObj.fam_npcs
        if @@fam_npcs.empty?
          nil
        else
          @@fam_npcs.dup
        end
      end

      def GameObj.fam_pcs
        if @@fam_pcs.empty?
          nil
        else
          @@fam_pcs.dup
        end
      end

      def GameObj.clear_container(container_id)
        @@contents[container_id] = Array.new
      end

      def GameObj.delete_container(container_id)
        @@contents.delete(container_id)
      end

      # Gets list of valid combat targets
      #
      # @return [Array<GameObj>] Array of targetable NPCs
      # @note Filters out dead/gone NPCs and certain nouns
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

      # Gets list of hidden targets
      #
      # @return [Array<String>] Array of hidden target IDs
      def GameObj.hidden_targets
        a = Array.new
        XMLData.current_target_ids.each { |id|
          unless @@npcs.find { |n| n.id == id }
            a.push(id)
          end
        }
        a
      end

      # Gets current target
      #
      # @return [GameObj, nil] Currently targeted object or nil
      def GameObj.target
        return (@@npcs + @@pcs).find { |n| n.id == XMLData.current_target_id }
      end

      # Gets list of dead NPCs
      #
      # @return [Array<GameObj>, nil] Array of dead NPCs or nil if none
      def GameObj.dead
        dead_list = Array.new
        for obj in @@npcs
          dead_list.push(obj) if obj.status == "dead"
        end
        return nil if dead_list.empty?

        return dead_list
      end

      # Gets container contents
      #
      # @return [Hash] Hash of container IDs to arrays of contents
      def GameObj.containers
        @@contents.dup
      end

      # Reloads game object data from XML
      #
      # @param filename [String, nil] Optional XML file path
      # @return [Boolean] True if loaded successfully
      def GameObj.reload(filename = nil)
        GameObj.load_data(filename)
      end

      def GameObj.merge_data(data, newData)
        return newData unless data.is_a?(Regexp)
        return Regexp.union(data, newData)
      end

      # Loads game object data from XML files
      #
      # @param filename [String, nil] Optional XML file path
      # @return [Boolean] True if loaded successfully
      # @raise [StandardError] If XML parsing fails
      def GameObj.load_data(filename = nil)
        filename = File.join(DATA_DIR, 'gameobj-data.xml') if filename.nil?
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
          rescue
            @@type_data = nil
            @@sellable_data = nil
            echo "error: GameObj.load_data: #{$!}"
            respond $!.backtrace[0..1]
            return false
          end
        else
          @@type_data = nil
          @@sellable_data = nil
          echo "error: GameObj.load_data: file does not exist: #{filename}"
          return false
        end
        filename = File.join(DATA_DIR, 'gameobj-custom', 'gameobj-data.xml')
        if (File.exist?(filename))
          begin
            File.open(filename) { |file|
              doc = REXML::Document.new(file.read)
              doc.elements.each('data/type') { |e|
                if (type = e.attributes['name'])
                  @@type_data[type] ||= Hash.new
                  @@type_data[type][:name]	  = GameObj.merge_data(@@type_data[type][:name], Regexp.new(e.elements['name'].text)) unless e.elements['name'].text.nil? or e.elements['name'].text.empty?
                  @@type_data[type][:noun]	  = GameObj.merge_data(@@type_data[type][:noun], Regexp.new(e.elements['noun'].text)) unless e.elements['noun'].text.nil? or e.elements['noun'].text.empty?
                  @@type_data[type][:exclude] = GameObj.merge_data(@@type_data[type][:exclude], Regexp.new(e.elements['exclude'].text)) unless e.elements['exclude'].text.nil? or e.elements['exclude'].text.empty?
                end
              }
              doc.elements.each('data/sellable') { |e|
                if (sellable = e.attributes['name'])
                  @@sellable_data[sellable] ||= Hash.new
                  @@sellable_data[sellable][:name]	  = GameObj.merge_data(@@sellable_data[sellable][:name], Regexp.new(e.elements['name'].text)) unless e.elements['name'].text.nil? or e.elements['name'].text.empty?
                  @@sellable_data[sellable][:noun]	  = GameObj.merge_data(@@sellable_data[sellable][:noun], Regexp.new(e.elements['noun'].text)) unless e.elements['noun'].text.nil? or e.elements['noun'].text.empty?
                  @@sellable_data[sellable][:exclude] = GameObj.merge_data(@@sellable_data[sellable][:exclude], Regexp.new(e.elements['exclude'].text)) unless e.elements['exclude'].text.nil? or e.elements['exclude'].text.empty?
                end
              }
            }
          rescue
            echo "error: Custom GameObj.load_data: #{$!}"
            respond $!.backtrace[0..1]
            return false
          end
        end
        return true
      end

      # Gets type definition data
      #
      # @return [Hash] Type pattern definitions
      def GameObj.type_data
        @@type_data
      end

      # Gets type cache data
      #
      # @return [Hash] Cached type lookups
      def GameObj.type_cache
        @@type_cache
      end

      # Gets sellable definition data
      #
      # @return [Hash] Sellable pattern definitions
      def GameObj.sellable_data
        @@sellable_data
      end
    end

    # start deprecated stuff
    class RoomObj < GameObj
    end
    # end deprecated stuff
  end
end