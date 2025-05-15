module Lich
  # Common utilities and classes used across Lich
  module Common
    # Represents the game world map and provides navigation/pathfinding capabilities
    class Map
      @@loaded                   = false
      @@load_mutex               = Mutex.new
      @@list                   ||= Array.new
      @@images                 ||= Array.new
      @@locations              ||= Array.new
      @@tags                   ||= Array.new
      @@current_room_mutex       = Mutex.new
      @@current_room_id        ||= nil
      @@current_room_count     ||= -1
      @@fuzzy_room_mutex         = Mutex.new
      @@fuzzy_room_id          ||= nil
      @@fuzzy_room_count       ||= -1
      @@current_location       ||= nil
      @@current_location_count ||= -1
      @@previous_room_id       ||= nil
      @@uids                     = {}

      # @return [Integer] Unique identifier for this room
      attr_reader :id

      # @return [String] Room title
      # @return [String] Room description 
      # @return [Array<String>] Available paths from this room
      # @return [Array<Integer>] Unique IDs for this room
      # @return [String] Location name
      # @return [String] Climate type
      # @return [String] Terrain type
      # @return [Hash] Movement commands to other rooms
      # @return [Hash] Time costs to other rooms
      # @return [String] Map image name
      # @return [Array<Integer>] Image coordinates
      # @return [Array<String>] Room tags
      # @return [Boolean] Whether to check location
      # @return [Array<String>] Unique loot in room
      attr_accessor :title, :description, :paths, :uid, :location, :climate, :terrain, :wayto, :timeto, :image, :image_coords, :tags, :check_location, :unique_loot

      # Creates a new Map room
      #
      # @param id [Integer] Room ID
      # @param title [Array<String>] Room titles
      # @param description [Array<String>] Room descriptions
      # @param paths [Array<String>] Available paths
      # @param uid [Array<Integer>] Unique IDs
      # @param location [String] Location name
      # @param climate [String] Climate type
      # @param terrain [String] Terrain type
      # @param wayto [Hash] Movement commands
      # @param timeto [Hash] Movement times
      # @param image [String] Map image name
      # @param image_coords [Array<Integer>] Image coordinates
      # @param tags [Array<String>] Room tags
      # @param check_location [Boolean] Whether to verify location
      # @param unique_loot [Array<String>] Unique loot items
      # @return [Map] New Map instance
      def initialize(id, title, description, paths, uid = [], location = nil, climate = nil, terrain = nil, wayto = {}, timeto = {}, image = nil, image_coords = nil, tags = [], check_location = nil, unique_loot = nil)
        @id, @title, @description, @paths, @uid, @location, @climate, @terrain, @wayto, @timeto, @image, @image_coords, @tags, @check_location, @unique_loot = id, title, description, paths, uid, location, climate, terrain, wayto, timeto, image, image_coords, tags, check_location, unique_loot
        @@list[@id] = self
      end

      # Gets the current room ID
      # @return [Integer] Current room ID 
      def Map.current_room_id; return @@current_room_id; end

      # Sets the current room ID
      # @param id [Integer] Room ID to set as current
      # @return [Integer] The set room ID
      def Map.current_room_id=(id); return @@current_room_id = id; end

      # Checks if map data is loaded
      # @return [Boolean] True if map is loaded
      def Map.loaded; return @@loaded; end

      # Gets previous room ID
      # @return [Integer] Previous room ID
      def Map.previous_room_id; return @@previous_room_id; end

      # Sets previous room ID
      # @param id [Integer] Room ID to set as previous
      # @return [Integer] The set previous room ID
      def Map.previous_room_id=(id); return @@previous_room_id = id; end

      # Gets fuzzy matched room ID
      # @return [Integer] Fuzzy matched room ID
      def fuzzy_room_id; return @@current_room_id; end

      # Checks if room is outside
      # @return [Boolean] True if room is outside
      def outside?; return @paths.last =~ /^Obvious paths:/ ? true : false; end

      # Converts room to integer ID
      # @return [Integer] Room ID
      def to_i; return @id; end

      # String representation of room
      # @return [String] Formatted room string
      def to_s
        return "##{@id} (u#{@uid[-1]}):\n#{@title[-1]} (#{@location})\n#{@description[-1]}\n#{@paths[-1]}"
      end

      # Detailed room inspection
      # @return [String] Instance variables and values
      def inspect
        return self.instance_variables.collect { |var| var.to_s + "=" + self.instance_variable_get(var).inspect }.join("\n")
      end

      # Gets fuzzy matched room ID
      # @return [Integer] Fuzzy matched room ID
      def Map.fuzzy_room_id; return @@fuzzy_room_id; end

      # Gets next available room ID
      # @return [Integer] Next free room ID
      def Map.get_free_id
        Map.load unless @@loaded
        return @@list.compact.max_by { |r| r.id }.id + 1
      end

      # Gets list of all rooms
      # @return [Array<Map>] Array of all map rooms
      def Map.list
        Map.load unless @@loaded
        return @@list
      end

      # Finds room by ID, UID or description
      # @param val [Integer,String] Room identifier
      # @return [Map,nil] Matching room or nil
      def Map.[](val)
        Map.load unless @@loaded
        if (val.class == Integer or val =~ /^[0-9]+$/)
          return @@list[val.to_i]
        elsif val =~ /^u(-?\d+)$/i
          uid_request = $1.dup.to_i
          return @@list[(Map.ids_from_uid(uid_request)[0]).to_i]
        else
          chkre = /#{val.strip.sub(/\.$/, '').gsub(/\.(?:\.\.)?/, '|')}/i
          chk = /#{Regexp.escape(val.strip)}/i
          return @@list.find { |room| room.title.find { |title| title =~ chk } } || @@list.find { |room| room.description.find { |desc| desc =~ chk } } || @@list.find { |room| room.description.find { |desc| desc =~ chkre } }
        end
      end

      # Gets current location name
      # @return [String,nil] Current location name or nil if unknown
      def Map.get_location
        unless XMLData.room_count == @@current_location_count
          if (script = Script.current)
            save_want_downstream = script.want_downstream
            script.want_downstream = true
            waitrt?
            location_result = dothistimeout 'location', 15, /^You carefully survey your surroundings and guess that your current location is .*? or somewhere close to it\.$|^You can't do that while submerged under water\.$|^You can't do that\.$|^It would be rude not to give your full attention to the performance\.$|^You can't do that while hanging around up here!$|^You are too distracted by the difficulty of staying alive in these treacherous waters to do that\.$|^You carefully survey your surroundings but are unable to guess your current location\.$|^Not in pitch darkness you don't\.$|^That is too difficult to consider here\.$/
            script.want_downstream = save_want_downstream
            @@current_location_count = XMLData.room_count
            if location_result =~ /^You can't do that while submerged under water\.$|^You can't do that\.$|^It would be rude not to give your full attention to the performance\.$|^You can't do that while hanging around up here!$|^You are too distracted by the difficulty of staying alive in these treacherous waters to do that\.$|^You carefully survey your surroundings but are unable to guess your current location\.$|^Not in pitch darkness you don't\.$|^That is too difficult to consider here\.$/
              @@current_location = false
            else
              @@current_location = /^You carefully survey your surroundings and guess that your current location is (.*?) or somewhere close to it\.$/.match(location_result).captures.first
            end
          else
            return nil
          end
        end
        return @@current_location
      end

      # Gets previous room
      # @return [Map,nil] Previous room or nil
      def Map.previous
        return nil if @@previous_room_id.nil?
        return @@list[@@previous_room_id]
      end

      # Gets previous room UID
      # @return [Integer] Previous room UID
      def Map.previous_uid
        return XMLData.previous_nav_rm
      end

      # Gets current room
      # @return [Map,nil] Current room or nil
      def Map.current
        Map.load unless @@loaded
        if Script.current
          return @@list[@@current_room_id] if XMLData.room_count == @@current_room_count and !@@current_room_id.nil?
        else
          return @@list[@@current_room_id] if XMLData.room_count == @@fuzzy_room_count and !@@current_room_id.nil?
        end
        ids = ((XMLData.room_id > 4294967296) ? [] : Map.ids_from_uid(XMLData.room_id))
        return Map.set_current(ids[0]) if ids.size == 1
        if ids.size > 1 and !@@current_room_id.nil? and (id = Map.match_multi_ids(ids))
          return Map.set_current(id)
        end
        return Map.match_no_uid()
      end

      # Sets current room
      # @param id [Integer] Room ID
      # @return [Map,nil] Set room or nil
      def Map.set_current(id)
        @@previous_room_id = @@current_room_id if id != @@current_room_id;
        @@current_room_id  = id
        return nil if id.nil?
        return @@list[id]
      end

      # Sets fuzzy matched room
      # @param id [Integer] Room ID
      # @return [Map,nil] Set room or nil
      def Map.set_fuzzy(id)
        @@previous_room_id = @@current_room_id if !id.nil? and id != @@current_room_id;
        @@current_room_id  = id
        return nil if id.nil?
        return @@list[id]
      end

      # Matches room from multiple IDs
      # @param ids [Array<Integer>] Room IDs to match
      # @return [Integer,nil] Matched room ID or nil
      def Map.match_multi_ids(ids)
        matches = ids.find_all { |s| @@list[@@current_room_id].wayto.keys.include?(s.to_s) }
        return matches[0] if matches.size == 1;
        return nil;
      end

      # Matches room without UID
      # @return [Map,nil] Matched room or nil
      def Map.match_no_uid()
        if (script = Script.current)
          return Map.set_current(Map.match_current(script))
        else
          return Map.set_fuzzy(Map.match_fuzzy())
        end
      end

      # Matches current room
      # @param script [Script] Current script context
      # @return [Integer,nil] Matched room ID or nil
      def Map.match_current(script)
        @@current_room_mutex.synchronize {
          peer_history = Hash.new
          need_set_desc_off = false
          check_peer_tag = proc { |r|
            begin
              script.ignore_pause = true
              peer_room_count = XMLData.room_count
              if (peer_tag = r.tags.find { |tag| tag =~ /^(set desc on; )?peer [a-z]+ =~ \/.+\/$/ })
                good = false
                need_desc, peer_direction, peer_requirement = /^(set desc on; )?peer ([a-z]+) =~ \/(.+)\/$/.match(peer_tag).captures
                need_desc = need_desc ? true : false
                if peer_history[peer_room_count][peer_direction][need_desc].nil?
                  if need_desc
                    unless (last_roomdesc = $_SERVERBUFFER_.reverse.find { |line| line =~ /<style id="roomDesc"\/>/ }) and (last_roomdesc =~ /<style id="roomDesc"\/>[^<]/)
                      put 'set description on'
                      need_set_desc_off = true
                    end
                  end
                  save_want_downstream = script.want_downstream
                  script.want_downstream = true
                  squelch_started = false
                  squelch_proc = proc { |server_string|
                    if squelch_started
                      if server_string =~ /<prompt/
                        DownstreamHook.remove('squelch-peer')
                      end
                      nil
                    elsif server_string =~ /^You peer/
                      squelch_started = true
                      nil
                    else
                      server_string
                    end
                  }
                  DownstreamHook.add('squelch-peer', squelch_proc)
                  result = dothistimeout "peer #{peer_direction}", 3, /^You peer|^\[Usage: PEER/
                  if result =~ /^You peer/
                    peer_results = Array.new
                    5.times {
                      if (line = get?)
                        peer_results.push line
                        break if line =~ /^Obvious/
                      end
                    }
                    if XMLData.room_count == peer_room_count
                      peer_history[peer_room_count] ||= Hash.new
                      peer_history[peer_room_count][peer_direction] ||= Hash.new
                      if need_desc
                        peer_history[peer_room_count][peer_direction][true] = peer_results
                        peer_history[peer_room_count][peer_direction][false] = peer_results
                      else
                        peer_history[peer_room_count][peer_direction][false] = peer_results
                      end
                    end
                  end
                  script.want_downstream = save_want_downstream
                end
                if peer_history[peer_room_count][peer_direction][need_desc].any? { |line| line =~ /#{peer_requirement}/ }
                  good = true
                else
                  good = false
                end
              else
                good = true
              end
            ensure
              script.ignore_pause = false
            end
            good
          }
          begin
            begin
              @@current_room_count = XMLData.room_count
              foggy_exits = (XMLData.room_exits_string =~ /^Obvious (?:exits|paths): obscured by a thick fog$/)
              if (room = @@list.find { |r|
                    r.title.include?(XMLData.room_title) and
                      r.description.include?(XMLData.room_description.strip) and
                      (r.unique_loot.nil? or (r.unique_loot.to_a - GameObj.loot.to_a.collect { |obj| obj.name }).empty?) and
                      (foggy_exits or r.paths.include?(XMLData.room_exits_string.strip) or r.tags.include?('random-paths')) and
                      (not r.check_location or r.location == Map.get_location) and check_peer_tag.call(r)
                  })
                redo unless @@current_room_count == XMLData.room_count
                return room.id
              else
                redo unless @@current_room_count == XMLData.room_count
                desc_regex = /#{Regexp.escape(XMLData.room_description.strip.sub(/\.+$/, '')).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
                if (room = @@list.find { |r|
                      r.title.include?(XMLData.room_title) and
                        (foggy_exits or r.paths.include?(XMLData.room_exits_string.strip) or r.tags.include?('random-paths')) and
                        (XMLData.room_window_disabled or r.description.any? { |desc| desc =~ desc_regex }) and
                        (r.unique_loot.nil? or (r.unique_loot.to_a - GameObj.loot.to_a.collect { |obj| obj.name }).empty?) and
                        (not r.check_location or r.location == Map.get_location) and check_peer_tag.call(r)
                    })
                  redo unless @@current_room_count == XMLData.room_count
                  return room.id
                else
                  redo unless @@current_room_count == XMLData.room_count
                  return nil
                end
              end
            end
          ensure
            put 'set description off' if need_set_desc_off
          end
        }
      end

      # Matches fuzzy room
      # @return [Integer,nil] Matched room ID or nil
      def Map.match_fuzzy()
        @@fuzzy_room_mutex.synchronize {
          @@fuzzy_room_count = XMLData.room_count
          begin
            foggy_exits = (XMLData.room_exits_string =~ /^Obvious (?:exits|paths): obscured by a thick fog$/)
            if (room = @@list.find { |r|
                  r.title.include?(XMLData.room_title) and
                    r.description.include?(XMLData.room_description.strip) and
                    (r.unique_loot.nil? or (r.unique_loot.to_a - GameObj.loot.to_a.collect { |obj| obj.name }).empty?) and
                    (foggy_exits or r.paths.include?(XMLData.room_exits_string.strip) or r.tags.include?('random-paths')) and
                    (not r.check_location or r.location == Map.get_location)
                })
              redo unless @@fuzzy_room_count == XMLData.room_count
              if room.tags.any? { |tag| tag =~ /^(set desc on; )?peer [a-z]+ =~ \/.+\/$/ }
                return nil
              else
                return room.id
              end
            else
              redo unless @@fuzzy_room_count == XMLData.room_count
              desc_regex = /#{Regexp.escape(XMLData.room_description.strip.sub(/\.+$/, '')).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
              if (room = @@list.find { |r|
                    r.title.include?(XMLData.room_title) and
                    (foggy_exits or r.paths.include?(XMLData.room_exits_string.strip) or r.tags.include?('random-paths')) and
                    (XMLData.room_window_disabled or r.description.any? { |desc| desc =~ desc_regex }) and
                    (r.unique_loot.nil? or (r.unique_loot.to_a - GameObj.loot.to_a.collect { |obj| obj.name }).empty?) and
                    (not r.check_location or r.location == Map.get_location)
                  })
                redo unless @@fuzzy_room_count == XMLData.room_count
                if room.tags.any? { |tag| tag =~ /^(set desc on; )?peer [a-z]+ =~ \/.+\/$/ }
                  return nil
                else
                  return room.id
                end
              else
                redo unless @@fuzzy_room_count == XMLData.room_count
                return nil
              end
            end
          end
        }
      end

      # Gets list of all locations
      # @return [Array<String>] List of locations
      def Map.locations
        Map.load unless @@loaded
        @@locations = @@list.each_with_object({}) { |r, h| h[r.location] = nil if !h.key?(r.location) }.keys if @@locations.empty?;
        return @@locations.dup
      end

      # Gets list of all map images
      # @return [Array<String>] List of map images
      def Map.images
        Map.load unless @@loaded
        @@images = @@list.each_with_object({}) { |r, h| h[r.image] = nil if !h.key?(r.image) }.keys if @@images.empty?;
        return @@images.dup
      end

      # Gets list of all room tags
      # @return [Array<String>] List of tags
      def Map.tags
        Map.load unless @@loaded
        @@tags = @@list.each_with_object({}) { |r, h| r.tags.each { |t| h[t] = nil if !h.key?(t) } }.keys if @@tags.empty?;
        return @@tags.dup
      end

      # Gets UID mappings
      # @return [Hash] UID to room ID mappings
      def Map.uids(); return @@uids; end

      # Clears UID mappings
      # @return [void]
      def Map.uids_clear(); @@uids.clear; end

      # Gets room IDs for a UID
      # @param n [Integer] UID to lookup
      # @return [Array<Integer>] Matching room IDs
      def Map.ids_from_uid(n); return (@@uids[n].nil? ? [] : @@uids[n]); end

      # Adds UID mapping
      # @param uid [Integer] UID to add
      # @param id [Integer] Room ID to map to
      # @return [void]
      def Map.uids_add(uid, id)
        if !@@uids.key?(uid)
          @@uids[uid] = [id]
        else
          @@uids[uid] << id if !@@uids[uid].include?(id)
        end
      end

      # Loads all UID mappings
      # @return [void]
      def Map.load_uids()
        Map.load unless @@loaded
        @@uids.clear
        @@list.each { |r|
          r.uid.each { |u| Map.uids_add(u, r.id) }
        }
      end

      # Clears map data
      # @return [Boolean] True if cleared
      def Map.clear
        @@load_mutex.synchronize {
          @@list.clear
          @@tags.clear
          @@locations.clear
          @@images.clear
          @@loaded = false
          GC.start
        }
        return true
      end

      # Reloads map data
      # @return [void]
      def Map.reload
        Map.clear
        Map.load
      end

      # Loads map data from file
      # @param filename [String,nil] Optional filename to load
      # @return [Boolean] True if loaded successfully
      def Map.load(filename = nil)
        if filename.nil?
          file_list = Dir.entries("#{DATA_DIR}/#{XMLData.game}").find_all { |fn| fn =~ /^map\-[0-9]+\.(?:dat|xml|json)$/i }.collect { |fn| "#{DATA_DIR}/#{XMLData.game}/#{fn}" }.sort.reverse
        else
          file_list = [filename]
        end
        if file_list.empty?
          respond "--- Lich: error: no map database found"
          return false
        end
        while (filename = file_list.shift)
          if filename =~ /\.json$/i
            if Map.load_json(filename)
              return true
            end
          elsif filename =~ /\.xml$/
            if Map.load_xml(filename)
              return true
            end
          else
            if Map.load_dat(filename)
              return true
            end
          end
        end
        return false
      end

      # Loads map from JSON file
      # @param filename [String,nil] Optional filename to load
      # @return [Boolean] True if loaded successfully
      def Map.load_json(filename = nil)
        @@load_mutex.synchronize {
          if @@loaded
            return true
          else
            if filename
              file_list = [filename]
            else
              file_list = Dir.entries("#{DATA_DIR}/#{XMLData.game}").find_all { |fn|
                fn =~ /^map\-[0-9]+\.json$/i
              }.collect { |fn|
                "#{DATA_DIR}/#{XMLData.game}/#{fn}"
              }.sort.reverse
            end
            if file_list.empty?
              respond "--- Lich: error: no map database found"
              return false
            end
            while (filename = file_list.shift)
              if File.exist?(filename)
                File.open(filename) { |f|
                  JSON.parse(f.read).each { |room|
                    room['wayto'].keys.each { |k|
                      if room['wayto'][k][0..2] == ';e '
                        room['wayto'][k] = StringProc.new(room['wayto'][k][3..-1])
                      end
                    }
                    room['timeto'].keys.each { |k|
                      if (room['timeto'][k].class == String) and (room['timeto'][k][0..2] == ';e ')
                        room['timeto'][k] = StringProc.new(room['timeto'][k][3..-1])
                      end
                    }
                    room['wayto'] ||= {}
                    room['timeto'] ||= {}
                    room['title'] ||= []
                    room['description'] ||= []
                    room['tags']  ||= []
                    room['uid']   ||= []
                    Map.new(room['id'], room['title'], room['description'], room['paths'], room['uid'], room['location'], room['climate'], room['terrain'], room['wayto'], room['timeto'], room['image'], room['image_coords'], room['tags'], room['check_location'], room['unique_loot'])
                  }
                }
                @@tags.clear
                respond "--- #{Script.current.name} Map loaded #{filename}"
                @@loaded = true
                Map.load_uids
                return true
              end
            end
          end
        }
      end

      # Loads map from DAT file
      # @param filename [String,nil] Optional filename to load
      # @return [Boolean] True if loaded successfully
      def Map.load_dat(filename = nil)
        @@load_mutex.synchronize {
          if @@loaded
            return true
          else
            if filename.nil?
              file_list = Dir.entries("#{DATA_DIR}/#{XMLData.game}").find_all { |fn| fn =~ /^map\-[0-9]+\.dat$/ }.collect { |fn| "#{DATA_DIR}/#{XMLData.game}/#{fn}" }.sort.reverse
            else
              file_list = [filename]
              respond "--- file_list = #{filename.inspect}"
            end
            if file_list.empty?
              respond "--- Lich: error: no map database found"
              return false
            end
            while (filename = file_list.shift)
              begin
                @@list = File.open(filename, 'rb') { |f| Marshal.load(f.read) }
                respond "--- Map loaded #{filename}" # if error
                @@loaded = true
                Map.load_uids
                return true
              rescue
                if file_list.empty?
                  respond "--- Lich: error: failed to load #{filename}: #{$!}"
                else
                  respond "--- warning: failed to load #{filename}: #{$!}"
                end
              end
            end
            return false
          end
        }
      end

      # Loads map from XML file
      # @param filename [String] XML filename to load
      # @return [Boolean] True if loaded successfully
      def Map.load_xml(filename = "#{DATA_DIR}/#{XMLData.game}/map.xml")
        @@load_mutex.synchronize {
          if @@loaded
            return true
          else
            unless File.exist?(filename)
              raise Exception.exception("MapDatabaseError"), "Fatal error: file `#{filename}' does not exist!"
            end
            missing_end = false
            current_tag = nil
            current_attributes = nil
            room = nil
            buffer = String.new
            unescape = { 'lt' => '<', 'gt' => '>', 'quot' => '"', 'apos' => "'", 'amp' => '&' }
            tag_start = proc { |element, attributes|
              current_tag = element
              current_attributes = attributes
              if element == 'room'
                room = Hash.new
                room['id'] = attributes['id'].to_i
                room['location'] = attributes['location']
                room['climate'] = attributes['climate']
                room['terrain'] = attributes['terrain']
                room['wayto'] = Hash.new
                room['timeto'] = Hash.new
                room['title'] = Array.new
                room['description'] = Array.new
                room['paths'] = Array.new
                room['tags'] = Array.new
                room['unique_loot'] = Array.new
                room['uid'] = Array.new
              elsif element =~ /^(?:image|tsoran)$/ and attributes['name'] and attributes['x'] and attributes['y'] and attributes['size']
                room['image'] = attributes['name']
                room['image_coords'] = [(attributes['x'].to_i - (attributes['size'] / 2.0).round), (attributes['y'].to_i - (attributes['size'] / 2.0).round), (attributes['x'].to_i + (attributes['size'] / 2.0).round), (attributes['y'].to_i + (attributes['size'] / 2.0).round)]
              elsif (element == 'image') and attributes['name'] and attributes['coords'] and (attributes['coords'] =~ /[0-9]+,[0-9]+,[0-9]+,[0-9]+/)
                room['image'] = attributes['name']
                room['image_coords'] = attributes['coords'].split(',').collect { |num| num.to_i }
              elsif element == 'map'
                missing_end = true
              end
            }
            text = proc { |text_string|
              if current_tag == 'tag'
                room