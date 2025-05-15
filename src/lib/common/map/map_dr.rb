module Lich
  module Common
    # Represents a map in the game, containing rooms and their properties.
    class Map
      @@loaded                   = false
      @@load_mutex               = Mutex.new
      @@list                   ||= Array.new
      @@tags                   ||= Array.new
      @@current_room_mutex       = Mutex.new
      @@current_room_id        ||= -1
      @@current_room_count     ||= -1
      @@fuzzy_room_mutex         = Mutex.new
      @@fuzzy_room_count       ||= -1
      @@current_location       ||= nil
      @@current_location_count ||= -1
      @@current_room_uid       ||= -1
      @@previous_room_id       ||= -1
      @@uids                     = {}

      attr_reader :id
      attr_accessor :title, :description, :paths, :location, :climate, :terrain, :wayto, :timeto, :image, :image_coords, :tags, :check_location, :unique_loot, :uid, :room_objects

      # Initializes a new Map instance.
      #
      # @param id [Integer] The unique identifier for the map.
      # @param title [Array<String>] The titles of the map.
      # @param description [Array<String>] The descriptions of the map.
      # @param paths [Array<String>] The paths available in the map.
      # @param uid [Array<Integer>] The unique identifiers for the room (default: []).
      # @param location [Object] The location of the map (default: nil).
      # @param climate [Object] The climate of the map (default: nil).
      # @param terrain [Object] The terrain of the map (default: nil).
      # @param wayto [Hash] The way to reach other rooms (default: {}).
      # @param timeto [Hash] The time to reach other rooms (default: {}).
      # @param image [String] The image associated with the map (default: nil).
      # @param image_coords [Array<Integer>] The coordinates of the image (default: nil).
      # @param tags [Array<String>] The tags associated with the map (default: []).
      # @param check_location [Object] The location check (default: nil).
      # @param unique_loot [Object] The unique loot in the map (default: nil).
      # @param _room_objects [Object] The room objects (default: nil).
      #
      # @return [Map] The newly created Map instance.
      def initialize(id, title, description, paths, uid = [], location = nil, climate = nil, terrain = nil, wayto = {}, timeto = {}, image = nil, image_coords = nil, tags = [], check_location = nil, unique_loot = nil, _room_objects = nil)
        @id, @title, @description, @paths, @uid, @location, @climate, @terrain, @wayto, @timeto, @image, @image_coords, @tags, @check_location, @unique_loot = id, title, description, paths, uid, location, climate, terrain, wayto, timeto, image, image_coords, tags, check_location, unique_loot
        @@list[@id] = self
      end

      # Returns the ID of the map as an integer.
      #
      # @return [Integer] The ID of the map.
      def to_i
        @id
      end

      # Returns a string representation of the map.
      #
      # @return [String] A formatted string containing the map's ID, UID, title, description, and paths.
      def to_s
        "##{@id} (#{@uid[-1]}):\n#{@title[-1]}\n#{@description[-1]}\n#{@paths[-1]}"
      end

      # Inspects the map object, returning its instance variables and their values.
      #
      # @return [String] A string representation of the map's instance variables.
      def inspect
        self.instance_variables.collect { |var| var.to_s + "=" + self.instance_variable_get(var).inspect }.join("\n")
      end

      # Retrieves a free ID for a new map.
      #
      # @return [Integer] A unique free ID for the map.
      # @raise [StandardError] If the map is not loaded.
      #
      # @example
      #   free_id = Map.get_free_id
      def Map.get_free_id
        Map.load unless @@loaded
        return @@list.compact.max_by { |r| r.id }.id + 1
      end

      # Returns the list of all maps.
      #
      # @return [Array<Map>] The list of maps.
      # @raise [StandardError] If the map is not loaded.
      #
      # @example
      #   maps = Map.list
      def Map.list
        Map.load unless @@loaded
        @@list
      end

      # Retrieves a map by its ID or UID.
      #
      # @param val [Integer, String] The ID or UID of the map to retrieve.
      #
      # @return [Map, nil] The map if found, otherwise nil.
      # @raise [StandardError] If the map is not loaded.
      #
      # @example
      #   map = Map[1] # Retrieves the map with ID 1
      def Map.[](val)
        Map.load unless @@loaded
        if (val.class == Integer) or val =~ /^[0-9]+$/
          @@list[val.to_i]
        elsif val =~ /^u(-?\d+)$/i
          uid_request = $1.dup.to_i
          @@list[(Map.ids_from_uid(uid_request)[0]).to_i]
        else
          chkre = /#{val.strip.sub(/\.$/, '').gsub(/\.(?:\.\.)?/, '|')}/i
          chk = /#{Regexp.escape(val.strip)}/i
          @@list.find { |room| room.title.find { |title| title =~ chk } } || @@list.find { |room| room.description.find { |desc| desc =~ chk } } || @@list.find { |room| room.description.find { |desc| desc =~ chkre } }
        end
      end

      # Returns the previous room in the map.
      #
      # @return [Map, nil] The previous room if it exists, otherwise nil.
      def Map.previous
        return @@list[@@previous_room_id]
      end

      # Returns the UID of the previous room.
      #
      # @return [Integer, nil] The UID of the previous room if it exists, otherwise nil.
      def Map.previous_uid
        return XMLData.previous_nav_rm
      end

      # Returns the current room in the map.
      #
      # @return [Map, nil] The current room if it exists, otherwise nil.
      # @raise [StandardError] If the map is not loaded.
      #
      # @example
      #   current_room = Map.current
      def Map.current # returns Map/Room
        Map.load unless @@loaded
        if Script.current
          return @@list[@@current_room_id] if XMLData.room_count == @@current_room_count and !@@current_room_id.nil?;
        else
          return @@list[@@current_room_id] if XMLData.room_count == @@fuzzy_room_count and !@@current_room_id.nil?;
        end
        ids = (XMLData.room_id.zero? ? [] : Map.ids_from_uid(XMLData.room_id))
        return Map.set_current(ids[0]) if (ids.size == 1)
        if ids.size > 1 and !@@current_room_id.nil? and (id = Map.match_multi_ids(ids))
          return Map.set_current(id)
        end
        return Map.match_no_uid()
      end

      # Matches the current room based on the script context.
      #
      # @return [Map, nil] The matched room if found, otherwise nil.
      def Map.match_no_uid() # returns Map/Room
        if (script = Script.current)
          return Map.set_current(Map.match_current(script))
        else
          return Map.set_fuzzy(Map.match_fuzzy())
        end
      end

      # Sets the current room based on a fuzzy match.
      #
      # @param id [Integer] The ID of the room to set as current.
      #
      # @return [Map, nil] The newly set room if successful, otherwise nil.
      def Map.set_fuzzy(id) # returns Map/Room
        @@previous_room_id = @@current_room_id if !id.nil? and id != @@current_room_id;
        @@current_room_id  = id
        return nil if id.nil?
        return @@list[id]
      end

      # Matches the current room based on the provided script.
      #
      # @param _script [Object] The script context to match against.
      #
      # @return [Integer, nil] The ID of the matched room if found, otherwise nil.
      def Map.match_current(_script) # returns id
        @@current_room_mutex.synchronize {
          Hash.new
          need_set_desc_off = false
          begin
            begin
              @@current_room_count = XMLData.room_count
              foggy_exits = (XMLData.room_exits_string =~ /^Obvious (?:exits|paths): obscured by a thick fog$/)
              if (room = @@list.find { |r|
                    r.title.include?(XMLData.room_title) and
                      r.description.include?(XMLData.room_description.strip) and
                      (foggy_exits or r.paths.include?(XMLData.room_exits_string.strip))
                  })
                redo unless @@current_room_count == XMLData.room_count
                if room.uid.any?
                  unless room.uid.include?(XMLData.room_id)
                    return nil
                  else
                    return room.id
                  end
                else
                  return room.id
                end
              else
                redo unless @@current_room_count == XMLData.room_count
                desc_regex = /#{Regexp.escape(XMLData.room_description.strip.sub(/\.+$/, '')).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
                if (room = @@list.find { |r|
                      r.title.include?(XMLData.room_title) and
                        (foggy_exits or r.paths.include?(XMLData.room_exits_string.strip)) and
                        (XMLData.room_window_disabled or r.description.any? { |desc| desc =~ desc_regex })
                    })
                  redo unless @@current_room_count == XMLData.room_count
                  if room.uid.any?
                    unless room.uid.include?(XMLData.room_id)
                      return nil
                    else
                      return room.id
                    end
                  else
                    return room.id
                  end
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

      # Matches a room based on fuzzy criteria.
      #
      # @return [Integer, nil] The ID of the matched room if found, otherwise nil.
      def Map.match_fuzzy() # returns id
        @@fuzzy_room_mutex.synchronize {
          @@fuzzy_room_count = XMLData.room_count
          begin
            foggy_exits = (XMLData.room_exits_string =~ /^Obvious (?:exits|paths): obscured by a thick fog$/)
            if (room = @@list.find { |r|
                  r.title.include?(XMLData.room_title) and
                    r.description.include?(XMLData.room_description.strip) and
                    (foggy_exits or r.paths.include?(XMLData.room_exits_string.strip))
                })
              redo unless @@fuzzy_room_count == XMLData.room_count

              if room.uid.any?
                unless room.uid.include?(XMLData.room_id)
                  return nil
                else
                  return room.id
                end
              elsif room.tags.any? { |tag| tag =~ /^(set desc on; )?peer [a-z]+ =~ \/.+\/$/ }
                return nil
              else
                return room.id
              end
            else
              redo unless @@fuzzy_room_count == XMLData.room_count
              desc_regex = /#{Regexp.escape(XMLData.room_description.strip.sub(/\.+$/, '')).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
              if (room = @@list.find { |r|
                    r.title.include?(XMLData.room_title) and
                    (foggy_exits or r.paths.include?(XMLData.room_exits_string.strip)) and
                    (XMLData.room_window_disabled or r.description.any? { |desc| desc =~ desc_regex })
                  })
                redo unless @@fuzzy_room_count == XMLData.room_count

                if room.uid.any?
                  unless room.uid.include?(XMLData.room_id)
                    return nil
                  else
                    return room.id
                  end
                elsif room.tags.any? { |tag| tag =~ /^(set desc on; )?peer [a-z]+ =~ \/.+\/$/ }
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

           # Returns the current room or creates a new one if none exists.
     # @return [Map/Room, nil] the current room if it exists, otherwise a new room or nil if no script is current.
     # @note This method will load the map if it hasn't been loaded yet.
     # @example
     #   room = Map.current_or_new
     #   puts room.title if room
     def Map.current_or_new # returns Map/Room
        return nil unless Script.current
        @@current_room_count = -1
        @@fuzzy_room_count = -1

        Map.load unless @@loaded

        room = nil

        id = Map.current ? Map.current.id : nil

        echo("Map: current room id is #{id.inspect}")
        unless id.nil?
          room = Map[id]
          unless XMLData.room_id.zero? || room.uid.include?(XMLData.room_id)
            room.uid << XMLData.room_id
            Map.uids_add(XMLData.room_id, room.id)
            echo "Map: Adding new uid for #{room.id}: #{XMLData.room_id}"
          end
          return Map.set_current(room.id)
        end
        id               = Map.get_free_id
        title            = [XMLData.room_title]
        description      = [XMLData.room_description.strip]
        paths            = [XMLData.room_exits_string.strip]
        uid              = (XMLData.room_id.zero? ? [] : [XMLData.room_id])
        room             = Map.new(id, title, description, paths, uid)
        Map.uids_add(XMLData.room_id, room.id) unless XMLData.room_id.zero?
        echo "mapped new room, set current room to #{room.id}"
        return Map.set_current(id)
      end

      # Adds a UID to the map's UID list.
      # @param uid [Integer] the unique identifier to add.
      # @param id [Integer] the room ID associated with the UID.
      # @return [void]
      # @note This method ensures that each UID is only associated with unique room IDs.
      def Map.uids_add(uid, id)
        if !@@uids.key?(uid)
          @@uids[uid] = [id]
        else
          @@uids[uid] << id if !@@uids[uid].include?(id)
        end
      end

      # Sets the current room based on the provided ID.
      # @param id [Integer] the ID of the room to set as current.
      # @return [Map/Room, nil] the room that was set as current, or nil if the ID is nil.
      # @note This method updates the previous room ID if the current room changes.
      def Map.set_current(id) # returns Map/Room
        @@previous_room_id = @@current_room_id if id != @@current_room_id;
        @@current_room_id  = id
        return nil if id.nil?
        return @@list[id]
      end

      # Matches multiple IDs against the current room's exits.
      # @param ids [Array<Integer>] the list of IDs to match.
      # @return [Integer, nil] the matched ID if exactly one match is found, otherwise nil.
      # @note This method only returns a match if there is exactly one valid exit.
      def Map.match_multi_ids(ids) # returns id
        matches = ids.find_all { |s| @@list[@@current_room_id].wayto.keys.include?(s.to_s) }
        return matches[0] if matches.size == 1;
        return nil;
      end

      # Retrieves all unique tags from the map.
      # @return [Array<String>] a duplicate of the list of unique tags.
      # @note This method loads the map if it hasn't been loaded yet.
      def Map.tags
        Map.load unless @@loaded
        if @@tags.empty?
          @@list.each { |r|
            r.tags.each { |t|
              @@tags.push(t) unless @@tags.include?(t)
            }
          }
        end
        @@tags.dup
      end

      # Loads UIDs from the map's list of rooms.
      # @return [void]
      # @note This method clears the existing UID list before loading.
      def Map.load_uids()
        Map.load unless @@loaded
        @@uids.clear
        @@list.each { |r|
          r.uid.each { |u|
            if @@uids[u].nil?
              @@uids[u] = [r.id]
            else
              @@uids[u] << r.id if !@@uids[u].include?(r.id)
            end
          }
        }
      end

      # Retrieves IDs associated with a given UID.
      # @param n [Integer] the UID to look up.
      # @return [Array<Integer>] an array of IDs associated with the UID, or an empty array if none exist.
      def Map.ids_from_uid(n)
        return (@@uids[n].nil? || n == 0 ? [] : @@uids[n])
      end

      # Clears the map's data.
      # @return [Boolean] true if the clear operation was successful.
      # @note This method synchronizes access to the map's data and triggers garbage collection.
      def Map.clear
        @@load_mutex.synchronize {
          @@list.clear
          @@tags.clear
          @@loaded = false
          GC.start
        }
        true
      end

      # Reloads the map by clearing and then loading it again.
      # @return [void]
      # @note This method will clear all current map data before reloading.
      def Map.reload
        Map.clear
        Map.load
      end

      # Loads the map from files in the specified directory.
      # @param filename [String, nil] the specific filename to load, or nil to load all map files.
      # @return [Boolean] true if the map was successfully loaded, false otherwise.
      # @note This method will respond with an error message if no map database is found.
      # @example
      #   success = Map.load
      #   puts "Map loaded successfully" if success
      def Map.load(filename = nil)
        if filename.nil?
          file_list = Dir.entries("#{DATA_DIR}/#{XMLData.game}").find_all { |filename| filename =~ /^map\-[0-9]+\.(?:dat|xml|json)$/i }.collect { |filename| "#{DATA_DIR}/#{XMLData.game}/#{filename}" }.sort.reverse
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

      # Loads a map from a JSON file.
      # @param filename [String, nil] the specific filename to load, or nil to load all JSON map files.
      # @return [Boolean] true if the map was successfully loaded, false otherwise.
      # @note This method will respond with an error message if no map database is found.
      def Map.load_json(filename = nil)
        @@load_mutex.synchronize {
          if @@loaded
            return true
          else
            if filename
              file_list = [filename]
              # respond "--- loading #{filename}" #if error
            else
              file_list = Dir.entries("#{DATA_DIR}/#{XMLData.game}").find_all { |filename|
                filename =~ /^map\-[0-9]+\.json$/i
              }.collect { |filename|
                "#{DATA_DIR}/#{XMLData.game}/#{filename}"
              }.sort.reverse
              # respond "--- loading #{filename}" #if error
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
                    room['tags'] ||= []
                    room['uid'] ||= []
                    Map.new(room['id'], room['title'], room['description'], room['paths'], room['uid'], room['location'], room['climate'], room['terrain'], room['wayto'], room['timeto'], room['image'], room['image_coords'], room['tags'], room['check_location'], room['unique_loot'])
                  }
                }
                @@tags.clear
                respond "--- Map loaded #{filename}" # if error
                @@loaded = true
                Map.load_uids
                return true
              end
            end
          end
        }
      end

      # Loads a map from a DAT file.
      # @param filename [String, nil] the specific filename to load, or nil to load all DAT map files.
      # @return [Boolean] true if the map was successfully loaded, false otherwise.
      # @note This method will respond with an error message if no map database is found.
      def Map.load_dat(filename = nil)
        @@load_mutex.synchronize {
          if @@loaded
            return true
          else
            if filename.nil?
              file_list = Dir.entries("#{DATA_DIR}/#{XMLData.game}").find_all { |filename| filename =~ /^map\-[0-9]+\.dat$/ }.collect { |filename| "#{DATA_DIR}/#{XMLData.game}/#{filename}" }.sort.reverse
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

      # Loads the map data from an XML file.
      #
      # @param filename [String] the path to the XML file to load. Defaults to "#{DATA_DIR}/#{XMLData.game}/map.xml".
      # @return [Boolean] returns true if the map is successfully loaded, false otherwise.
      # @raise [Exception] raises an exception if the file does not exist.
      # @example
      #   Map.load_xml
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
                room['room_objects'] = Array.new
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
                room['tags'].push(text_string)
              elsif current_tag =~ /^(?:title|description|paths|unique_loot|tag|room_objects)$/
                room[current_tag].push(text_string)
              elsif current_tag =~ /^(?:uid)$/
                room[current_tag].push(text_string.to_i)
              elsif current_tag == 'exit' and current_attributes['target']
                if current_attributes['type'].downcase == 'string'
                  room['wayto'][current_attributes['target']] = text_string
                end
                if current_attributes['cost'] =~ /^[0-9\.]+$/
                  room['timeto'][current_attributes['target']] = current_attributes['cost'].to_f
                elsif current_attributes['cost'].length > 0
                  room['timeto'][current_attributes['target']] = StringProc.new(current_attributes['cost'])
                else
                  room['timeto'][current_attributes['target']] = 0.2
                end
              end
            }
            tag_end = proc { |element|
              if element == 'room'
                room['unique_loot'] = nil if room['unique_loot'].empty?
                room['room_objects'] = nil if room['room_objects'].empty?
                Map.new(room['id'], room['title'], room['description'], room['paths'], room['uid'], room['location'], room['climate'], room['terrain'], room['wayto'], room['timeto'], room['image'], room['image_coords'], room['tags'], room['check_location'], room['unique_loot'], room['room_objects'])
              elsif element == 'map'
                missing_end = false
              end
              current_tag = nil
            }
            begin
              File.open(filename) { |file|
                while (line = file.gets)
                  buffer.concat(line)
                  # fixme: remove   (?=<)   ?
                  while (str = buffer.slice!(/^<([^>]+)><\/\1>|^[^<]+(?=<)|^<[^<]+>/))
                    if str[0, 1] == '<'
                      if str[1, 1] == '/'
                        element = /^<\/([^\s>\/]+)/.match(str).captures.first
                        tag_end.call(element)
                      else
                        if str =~ /^<([^>]+)><\/\1>/
                          element = $1
                          tag_start.call(element)
                          text.call('')
                          tag_end.call(element)
                        else
                          element = /^<([^\s>\/]+)/.match(str).captures.first
                          attributes = Hash.new
                          str.scan(/([A-z][A-z0-9_\-]*)=(["'])(.*?)\2/).each { |attr| attributes[attr[0]] = attr[2].gsub(/&(#{unescape.keys.join('|')});/) { unescape[$1] } }
                          tag_start.call(element, attributes)
                          tag_end.call(element) if str[-2, 1] == '/'
                        end
                      end
                    else
                      text.call(str.gsub(/&(#{unescape.keys.join('|')});/) { unescape[$1] })
                    end
                  end
                end
              }
              if missing_end
                respond "--- Lich: error: failed to load #{filename}: unexpected end of file"
                return false
              end
              @@tags.clear
              Map.load_uids
              @@loaded = true
              return true
            rescue
              respond "--- Lich: error: failed to load #{filename}: #{$!}"
              return false
            end
          end
        }
      end

      # Saves the current map data to a file.
      #
      # @param filename [String] the path to the file where the map data will be saved. Defaults to "#{DATA_DIR}/#{XMLData.game}/map-#{Time.now.to_i}.dat".
      # @return [void]
      # @raise [Exception] raises an exception if there is an error during file operations.
      # @example
      #   Map.save
      def Map.save(filename = "#{DATA_DIR}/#{XMLData.game}/map-#{Time.now.to_i}.dat")
        if File.exist?(filename)
          respond "--- Backing up map database"
          begin
            # fixme: does this work on all platforms? File.rename(filename, "#{filename}.bak")
            File.open(filename, 'rb') { |infile|
              File.open("#{filename}.bak", 'wb') { |outfile|
                outfile.write(infile.read)
              }
            }
          rescue
            respond "--- Lich: error: #{$!}"
          end
        end
        begin
          File.open(filename, 'wb') { |f| f.write(Marshal.dump(@@list)) }
          @@tags.clear
          respond "--- Map database saved"
        rescue
          respond "--- Lich: error: #{$!}"
        end
      end

      # Converts the current map data to JSON format.
      #
      # @param args [Array] optional arguments for JSON generation.
      # @return [String] the JSON representation of the map data.
      # @example
      #   Map.to_json
      def Map.to_json(*args)
        @@list.delete_if { |r| r.nil? }
        @@list.to_json(args)
      end

      # Converts the instance of the map to JSON format.
      #
      # @param _args [Array] optional arguments for JSON generation.
      # @return [String] the JSON representation of the instance.
      # @example
      #   map_instance.to_json
      def to_json(*_args)
        mapjson = ({
          :id             => @id,
          :title          => @title,
          :description    => @description,
          :paths          => @paths,
          :location       => @location,
          :climate        => @climate,
          :terrain        => @terrain,
          :wayto          => @wayto,
          :timeto         => @timeto,
          :image          => @image,
          :image_coords   => @image_coords,
          :tags           => @tags,
          :check_location => @check_location,
          :unique_loot    => @unique_loot,
          :uid            => @uid,
        }).delete_if { |_a, b| b.nil? or (b.class == Array and b.empty?) };
        JSON.pretty_generate(mapjson);
      end

      # Saves the current map data to a JSON file.
      #
      # @param filename [String] the path to the JSON file where the map data will be saved. Defaults to "#{DATA_DIR}/#{XMLData.game}/map-#{Time.now.to_i}.json".
      # @return [void]
      # @raise [Exception] raises an exception if there is an error during file operations.
      # @example
      #   Map.save_json
      def Map.save_json(filename = "#{DATA_DIR}/#{XMLData.game}/map-#{Time.now.to_i}.json")
        if File.exist?(filename)
          respond "File exists!  Backing it up before proceeding..."
          begin
            File.open(filename, 'rb') { |infile|
              File.open("#{filename}.bak", "wb:UTF-8") { |outfile|
                outfile.write(infile.read)
              }
            }
          rescue
            respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
            Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
          end
        end
        File.open(filename, 'wb:UTF-8') { |file|
          file.write(Map.to_json)
        }
        respond "#{filename} saved"
      end

      # Saves the map data to an XML file.
      #
      # @param filename [String] the name of the file to save the map data to.
      #   Defaults to "#{DATA_DIR}/#{XMLData.game}/map-#{Time.now.to_i}.xml".
      # @return [void]
      # @raise [Exception] if there is an error during file operations.
      # @example
      #   Map.save_xml
      #
      # @note This method will back up the existing file if it already exists.
      def Map.save_xml(filename = "#{DATA_DIR}/#{XMLData.game}/map-#{Time.now.to_i}.xml")
        if File.exist?(filename)
          respond "File exists!  Backing it up before proceeding..."
          begin
            File.open(filename, 'rb') { |infile|
              File.open("#{filename}.bak", "wb") { |outfile|
                outfile.write(infile.read)
              }
            }
          rescue
            respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
            Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
          end
        end
        begin
          escape = { '<' => '&lt;', '>' => '&gt;', '"' => '&quot;', "'" => "&apos;", '&' => '&amp;' }
          File.open(filename, 'w') { |file|
            file.write "<map>\n"
            @@list.each { |room|
              next if room == nil
              if room.location
                location = " location=#{(room.location.gsub(/(<|>|"|'|&)/) { escape[$1] }).inspect}"
              else
                location = ''
              end
              if room.climate
                climate = " climate=#{(room.climate.gsub(/(<|>|"|'|&)/) { escape[$1] }).inspect}"
              else
                climate = ''
              end
              if room.terrain
                terrain = " terrain=#{(room.terrain.gsub(/(<|>|"|'|&)/) { escape[$1] }).inspect}"
              else
                terrain = ''
              end
              file.write "   <room id=\"#{room.id}\"#{location}#{climate}#{terrain}>\n"
              room.title.each { |title| file.write "      <title>#{title.gsub(/(<|>|"|'|&)/) { escape[$1] }}</title>\n" }
              room.description.each { |desc| file.write "      <description>#{desc.gsub(/(<|>|"|'|&)/) { escape[$1] }}</description>\n" }
              room.paths.each { |paths| file.write "      <paths>#{paths.gsub(/(<|>|"|'|&)/) { escape[$1] }}</paths>\n" }
              room.tags.each { |tag| file.write "      <tag>#{tag.gsub(/(<|>|"|'|&)/) { escape[$1] }}</tag>\n" }
              room.uid.each { |u| file.write "      <uid>#{u}</uid>\n" }
              room.unique_loot.to_a.each { |loot| file.write "      <unique_loot>#{loot.gsub(/(<|>|"|'|&)/) { escape[$1] }}</unique_loot>\n" }
              room.room_objects.to_a.each { |loot| file.write "      <room_objects>#{loot.gsub(/(<|>|"|'|&)/) { escape[$1] }}</room_objects>\n" }
              file.write "      <image name=\"#{room.image.gsub(/(<|>|"|'|&)/) { escape[$1] }}\" coords=\"#{room.image_coords.join(',')}\" />\n" if room.image and room.image_coords
              room.wayto.keys.each { |target|
                if room.timeto[target].class == Proc
                  cost = " cost=\"#{room.timeto[target]._dump.gsub(/(<|>|"|'|&)/) { escape[$1] }}\""
                elsif room.timeto[target]
                  cost = " cost=\"#{room.timeto[target]}\""
                else
                  cost = ''
                end
                if room.wayto[target].class == Proc
                  file.write "      <exit target=\"#{target}\" type=\"Proc\"#{cost}>#{room.wayto[target]._dump.gsub(/(<|>|"|'|&)/) { escape[$1] }}</exit>\n"
                else
                  file.write "      <exit target=\"#{target}\" type=\"#{room.wayto[target].class}\"#{cost}>#{room.wayto[target].gsub(/(<|>|"|'|&)/) { escape[$1] }}</exit>\n"
                end
              }
              file.write "   </room>\n"
            }
            file.write "</map>\n"
          }
          @@tags.clear
          respond "--- map database saved to: #{filename}"
        rescue
          respond $!
        end
        GC.start
      end

      # Estimates the time required to traverse a sequence of rooms.
      #
      # @param array [Array] an array of room identifiers.
      # @return [Float] the estimated time to traverse the rooms.
      # @raise [Exception] if the input is not an array.
      # @example
      #   time = Map.estimate_time([1, 2, 3])
      def Map.estimate_time(array)
        Map.load unless @@loaded
        unless array.class == Array
          raise Exception.exception("MapError"), "Map.estimate_time was given something not an array!"
        end
        time = 0.to_f
        until array.length < 2
          room = array.shift
          if (t = Map[room].timeto[array.first.to_s])
            if t.class == Proc
              time += t.call.to_f
            else
              time += t.to_f
            end
          else
            time += "0.2".to_f
          end
        end
        time
      end

      # Finds the shortest path from a source room to a destination room.
      #
      # @param source [Map, String] the source room or its identifier.
      # @param destination [Integer, nil] the destination room identifier.
      # @return [Array, nil] the shortest path as an array of room identifiers or nil if invalid.
      # @example
      #   path = Map.dijkstra(1, 2)
      def Map.dijkstra(source, destination = nil)
        if source.class == Map
          source.dijkstra(destination)
        elsif (room = Map[source])
          room.dijkstra(destination)
        else
          echo "Map.dijkstra: error: invalid source room"
          nil
        end
      end

      # Implements Dijkstra's algorithm to find the shortest path.
      #
      # @param destination [Integer, Array, nil] the destination room identifier or identifiers.
      # @return [Array, nil] the previous room identifiers and shortest distances or nil if an error occurs.
      # @example
      #   previous, distances = dijkstra(2)
      def dijkstra(destination = nil)
        begin
          Map.load unless @@loaded
          source = @id
          visited = Array.new
          shortest_distances = Array.new
          previous = Array.new
          pq = [source]
          pq_push = proc { |val|
            for i in 0...pq.size
              if shortest_distances[val] <= shortest_distances[pq[i]]
                pq.insert(i, val)
                break
              end
            end
            pq.push(val) if i.nil? or (i == pq.size - 1)
          }
          visited[source] = true
          shortest_distances[source] = 0
          if destination.nil?
            until pq.size == 0
              v = pq.shift
              visited[v] = true
              @@list[v].wayto.keys.each { |adj_room|
                adj_room_i = adj_room.to_i
                unless visited[adj_room_i]
                  if @@list[v].timeto[adj_room].class == Proc
                    nd = @@list[v].timeto[adj_room].call
                  else
                    nd = @@list[v].timeto[adj_room]
                  end
                  if nd
                    nd += shortest_distances[v]
                    if shortest_distances[adj_room_i].nil? or (shortest_distances[adj_room_i] > nd)
                      shortest_distances[adj_room_i] = nd
                      previous[adj_room_i] = v
                      pq_push.call(adj_room_i)
                    end
                  end
                end
              }
            end
          elsif destination.class == Integer
            until pq.size == 0
              v = pq.shift
              break if v == destination
              visited[v] = true
              @@list[v].wayto.keys.each { |adj_room|
                adj_room_i = adj_room.to_i
                unless visited[adj_room_i]
                  if @@list[v].timeto[adj_room].class == Proc
                    nd = @@list[v].timeto[adj_room].call
                  else
                    nd = @@list[v].timeto[adj_room]
                  end
                  if nd
                    nd += shortest_distances[v]
                    if shortest_distances[adj_room_i].nil? or (shortest_distances[adj_room_i] > nd)
                      shortest_distances[adj_room_i] = nd
                      previous[adj_room_i] = v
                      pq_push.call(adj_room_i)
                    end
                  end
                end
              }
            end
          elsif destination.class == Array
            dest_list = destination.collect { |dest| dest.to_i }
            until pq.size == 0
              v = pq.shift
              break if dest_list.include?(v) and (shortest_distances[v] < 20)
              visited[v] = true
              @@list[v].wayto.keys.each { |adj_room|
                adj_room_i = adj_room.to_i
                unless visited[adj_room_i]
                  if @@list[v].timeto[adj_room].class == Proc
                    nd = @@list[v].timeto[adj_room].call
                  else
                    nd = @@list[v].timeto[adj_room]
                  end
                  if nd
                    nd += shortest_distances[v]
                    if shortest_distances[adj_room_i].nil? or (shortest_distances[adj_room_i] > nd)
                      shortest_distances[adj_room_i] = nd
                      previous[adj_room_i] = v
                      pq_push.call(adj_room_i)
                    end
                  end
                end
              }
            end
          end
          return previous, shortest_distances
        rescue
          echo "Map.dijkstra: error: #{$!}"
          respond $!.backtrace
          nil
        end
      end

      # Finds a path from a source room to a destination room.
      #
      # @param source [Map, String] the source room or its identifier.
      # @param destination [Integer] the destination room identifier.
      # @return [Array, nil] the path as an array of room identifiers or nil if invalid.
      # @example
      #   path = Map.findpath(1, 2)
      def Map.findpath(source, destination)
        if source.class == Map
          source.path_to(destination)
        elsif (room = Map[source])
          room.path_to(destination)
        else
          echo "Map.findpath: error: invalid source room"
          nil
        end
      end

      # Finds the path to a destination room.
      #
      # @param destination [Integer] the destination room identifier.
      # @return [Array, nil] the path as an array of room identifiers or nil if invalid.
      # @example
      #   path = path_to(2)
      def path_to(destination)
        Map.load unless @@loaded
        destination = destination.to_i
        previous, _ = dijkstra(destination)
        return nil unless previous[destination]
        path = [destination]
        path.push(previous[path[-1]]) until previous[path[-1]] == @id
        path.reverse!
        path.pop
        return path
      end

      # Finds the nearest room by a specific tag.
      #
      # @param tag_name [String] the tag to search for.
      # @return [Integer, nil] the nearest room identifier or nil if not found.
      # @example
      #   nearest = find_nearest_by_tag("treasure")
      def find_nearest_by_tag(tag_name)
        target_list = Array.new
        @@list.each { |room| target_list.push(room.id) if room.tags.include?(tag_name) }
        _, shortest_distances = Map.dijkstra(@id, target_list)
        if target_list.include?(@id)
          @id
        else
          target_list.delete_if { |room_num| shortest_distances[room_num].nil? }
          target_list.sort { |a, b| shortest_distances[a] <=> shortest_distances[b] }.first
        end
      end

      # Finds all nearest rooms by a specific tag.
      #
      # @param tag_name [String] the tag to search for.
      # @return [Array] an array of nearest room identifiers.
      # @example
      #   nearest_rooms = find_all_nearest_by_tag("treasure")
      def find_all_nearest_by_tag(tag_name)
        target_list = Array.new
        @@list.each { |room| target_list.push(room.id) if room.tags.include?(tag_name) }
        _, shortest_distances = Map.dijkstra(@id)
        target_list.delete_if { |room_num| shortest_distances[room_num].nil? }
        target_list.sort { |a, b| shortest_distances[a] <=> shortest_distances[b] }
      end

      # Finds the nearest room from a list of target rooms.
      #
      # @param target_list [Array] an array of target room identifiers.
      # @return [Integer, nil] the nearest room identifier or nil if not found.
      # @example
      #   nearest = find_nearest([1, 2, 3])
      def find_nearest(target_list)
        target_list = target_list.collect { |num| num.to_i }
        if target_list.include?(@id)
          @id
        else
          _, shortest_distances = Map.dijkstra(@id, target_list)
          target_list.delete_if { |room_num| shortest_distances[room_num].nil? }
          target_list.sort { |a, b| shortest_distances[a] <=> shortest_distances[b] }.first
        end
      end
    end

    # Represents a room in the map.
    class Room < Map
      # Handles missing methods by delegating to the superclass.
      #
      # @param args [Array] the arguments for the missing method.
      # @return [void]
      def Room.method_missing(*args)
        super(*args)
      end
    end

    # Deprecated methods for the Map class.
    #
    # @deprecated Use the new methods instead.
    class Map
      # Returns the description of the map.
      #
      # @return [String] the description of the map.
      # @example
      #   description = map.desc
      def desc
        @description
      end

      # Returns the name of the map.
      #
      # @return [String] the name of the map.
      # @example
      #   name = map.map_name
      def map_name
        @image
      end

      # Returns the x-coordinate of the map's center.
      #
      # @return [Integer, nil] the x-coordinate or nil if no image coordinates are set.
      # @example
      #   x = map.map_x
      def map_x
        if @image_coords.nil?
          nil
        else
          ((image_coords[0] + image_coords[2]) / 2.0).round
        end
      end

      # Returns the y-coordinate of the map's center.
      #
      # @return [Integer, nil] the y-coordinate or nil if no image coordinates are set.
      # @example
      #   y = map.map_y
      def map_y
        if @image_coords.nil?
          nil
        else
          ((image_coords[1] + image_coords[3]) / 2.0).round
        end
      end

      # Returns the size of the map's rooms.
      #
      # @return [Integer, nil] the room size or nil if no image coordinates are set.
      # @example
      #   size = map.map_roomsize
      def map_roomsize
        if @image_coords.nil?
          nil
        else
          image_coords[2] - image_coords[0]
        end
      end

      # Returns nil as a placeholder for geographical data.
      #
      # @return [nil]
      # @example
      #   geo_data = map.geo
      def geo
        nil
      end
    end
  end
end
