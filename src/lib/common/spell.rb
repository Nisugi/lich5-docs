# Core module for spell management and spell-related functionality in Lich5
module Lich
  # Common utilities and classes shared across Lich
  module Common
    # Represents a spell in the game with all its properties and behaviors
    class Spell
      @@list ||= Array.new
      @@loaded ||= false
      @@cast_lock ||= Array.new
      @@bonus_list ||= Array.new
      @@cost_list ||= Array.new
      @@load_mutex = Mutex.new
      @@after_stance = nil

      # @return [Integer] The spell number
      # @return [String] The name of the spell
      # @return [Time] When the spell was last cast
      # @return [String] Message shown when spell goes up
      # @return [String] Message shown when spell goes down
      # @return [String] The circle/school the spell belongs to
      # @return [Boolean] Whether the spell is currently active
      # @return [String] The type of spell (attack, defense, utility etc)
      # @return [String] Custom casting procedure
      # @return [Boolean] Whether the spell uses real time duration
      # @return [Boolean] Whether the spell persists through death
      # @return [String] Who can be targeted with the spell (self/all/group)
      # @return [Boolean] Whether the spell requires incanting
      attr_reader :num, :name, :timestamp, :msgup, :msgdn, :circle, :active, :type, :cast_proc, :real_time, :persist_on_death, :availability, :no_incant

      # @return [Boolean] Whether the spell requires specific stance
      # @return [Boolean] Whether the spell can be channeled 
      attr_accessor :stance, :channel

      @@prepare_regex = Regexp.union(
        /^You already have a spell readied!  You must RELEASE it if you wish to prepare another!$/,
        /^Your spell(?:song)? is ready\./,
        /^You can't think clearly enough to prepare a spell!$/,
        /^You are concentrating too intently .*?to prepare a spell\.$/,
        /^You are too injured to make that dextrous of a movement/,
        /^The searing pain in your throat makes that impossible/,
        /^But you don't have any mana!\.$/,
        /^You can't make that dextrous of a move!$/,
        /^As you begin to prepare the spell the wind blows small objects at you thwarting your attempt\.$/,
        /^You do not know that spell!$/,
        /^All you manage to do is cough up some blood\.$/,
        /^The incantations of countless spells swirl through your mind as a golden light flashes before your eyes\./
      )

      @@results_regex = Regexp.union(
        /^(?:Cast|Sing) Roundtime [0-9]+ Seconds?\.$/,
        /^Cast at what\?$/,
        /^But you don't have any mana!$/,
        /^You don't have a spell prepared!$/,
        /keeps? the spell from working\./,
        /^Be at peace my child, there is no need for spells of war in here\.$/,
        /Spells of War cannot be cast/,
        /^As you focus on your magic, your vision swims with a swirling haze of crimson\.$/,
        /^Your magic fizzles ineffectually\.$/,
        /^All you manage to do is cough up some blood\.$/,
        /^And give yourself away!  Never!$/,
        /^You are unable to do that right now\.$/,
        /^You feel a sudden rush of power as you absorb [0-9]+ mana!$/,
        /^You are unable to drain it!$/,
        /leaving you casting at nothing but thin air!$/,
        /^You don't seem to be able to move to do that\.$/,
        /^Provoking a GameMaster is not such a good idea\.$/,
        /^You can't think clearly enough to prepare a spell!$/,
        /^You do not currently have a target\.$/,
        /The incantations of countless spells swirl through your mind as a golden light flashes before your eyes\./,
        /You can only evoke certain spells\./,
        /You can only channel certain spells for extra power\./,
        /That is not something you can prepare\./,
        /^\[Spell preparation time: \d seconds?\]$/,
        /^You are too injured to make that dextrous of a movement/,
        /^You can't make that dextrous of a move!$/
      )

      # Creates a new Spell instance from XML data
      #
      # @param xml_spell [REXML::Element] The XML element containing spell data
      # @return [Spell] The new spell instance
      def initialize(xml_spell)
        @num = xml_spell.attributes['number'].to_i
        @name = xml_spell.attributes['name']
        @type = xml_spell.attributes['type']
        @no_incant = ((xml_spell.attributes['incant'] == 'no') ? true : false)
        if xml_spell.attributes['availability'] == 'all'
          @availability = 'all'
        elsif xml_spell.attributes['availability'] == 'group'
          @availability = 'group'
        else
          @availability = 'self-cast'
        end
        @bonus = Hash.new
        xml_spell.elements.find_all { |e| e.name == 'bonus' }.each { |e|
          @bonus[e.attributes['type']] = e.text
        }
        @msgup = xml_spell.elements.find_all { |e| (e.name == 'message') and (e.attributes['type'].downcase == 'start') }.collect { |e| e.text }.join('$|^')
        @msgup = nil if @msgup.empty?
        @msgdn = xml_spell.elements.find_all { |e| (e.name == 'message') and (e.attributes['type'].downcase == 'end') }.collect { |e| e.text }.join('$|^')
        @msgdn = nil if @msgdn.empty?
        @stance = ((xml_spell.attributes['stance'] =~ /^(yes|true)$/i) ? true : false)
        @channel = ((xml_spell.attributes['channel'] =~ /^(yes|true)$/i) ? true : false)
        @cost = Hash.new
        xml_spell.elements.find_all { |e| e.name == 'cost' }.each { |xml_cost|
          @cost[xml_cost.attributes['type'].downcase] ||= Hash.new
          if xml_cost.attributes['cast-type'].downcase == 'target'
            @cost[xml_cost.attributes['type'].downcase]['target'] = xml_cost.text
          else
            @cost[xml_cost.attributes['type'].downcase]['self'] = xml_cost.text
          end
        }
        @duration = Hash.new
        xml_spell.elements.find_all { |e| e.name == 'duration' }.each { |xml_duration|
          if xml_duration.attributes['cast-type'].downcase == 'target'
            cast_type = 'target'
          else
            cast_type = 'self'
            if xml_duration.attributes['real-time'] =~ /^(yes|true)$/i
              @real_time = true
            else
              @real_time = false
            end
          end
          @duration[cast_type] = Hash.new
          @duration[cast_type][:duration] = xml_duration.text
          @duration[cast_type][:stackable] = (xml_duration.attributes['span'].downcase == 'stackable')
          @duration[cast_type][:refreshable] = (xml_duration.attributes['span'].downcase == 'refreshable')
          if xml_duration.attributes['multicastable'] =~ /^(yes|true)$/i
            @duration[cast_type][:multicastable] = true
          else
            @duration[cast_type][:multicastable] = false
          end
          if xml_duration.attributes['persist-on-death'] =~ /^(yes|true)$/i
            @persist_on_death = true
          else
            @persist_on_death = false
          end
          if xml_duration.attributes['max']
            @duration[cast_type][:max_duration] = xml_duration.attributes['max'].to_f
          else
            @duration[cast_type][:max_duration] = 250.0
          end
        }
        @cast_proc = xml_spell.elements['cast-proc'].text
        @timestamp = Time.now
        @timeleft = 0
        @active = false
        @circle = (num.to_s.length == 3 ? num.to_s[0..0] : num.to_s[0..1])
        @@list.push(self) unless @@list.find { |spell| spell.num == @num }
      end

      # Sets the stance to return to after casting
      #
      # @param val [String] The stance to return to
      # @return [String] The new after-stance value
      def Spell.after_stance=(val)
        @@after_stance = val
      end

      # Gets the stance to return to after casting
      #
      # @return [String] The after-stance value
      def Spell.after_stance
        @@after_stance
      end

      # Loads spell data from XML file
      #
      # @param filename [String, nil] Optional XML file path, defaults to effect-list.xml
      # @return [Boolean] True if load successful, false otherwise
      # @raise [StandardError] If file cannot be loaded or parsed
      def Spell.load(filename = nil)
        if filename.nil?
          filename = File.join(DATA_DIR, 'effect-list.xml')
          unless File.exist?(filename)
            begin
              File.write(filename, URI.open('https://raw.githubusercontent.com/elanthia-online/scripts/master/scripts/effect-list.xml').read)
              Lich.log('effect-list.xml missing from DATA dir. Downloaded effect-list.xml from EO\Scripts GitHub complete.')
            rescue StandardError
              respond "--- Lich: error: Spell.load: #{$!}"
              Lich.log "error: Spell.load: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
              Lich.log('Github retrieval of effect-list.xml failed, trying ;repository instead.')
              Script.run('repository', 'download effect-list.xml --game=gs')
              return false unless File.exist?(filename)
            end
          end
        end
        Script.current
        @@load_mutex.synchronize {
          return true if @loaded
          begin
            spell_times = Hash.new
            unless @@list.empty?
              @@list.each { |spell| spell_times[spell.num] = spell.timeleft if spell.active? }
              @@list.clear
            end
            File.open(filename) { |file|
              xml_doc = REXML::Document.new(file)
              xml_root = xml_doc.root
              xml_root.elements.each { |xml_spell| Spell.new(xml_spell) }
            }
            @@list.each { |spell|
              if spell_times[spell.num]
                spell.timeleft = spell_times[spell.num]
                spell.active = true
              end
            }
            @@bonus_list = @@list.collect { |spell| spell._bonus.keys }.flatten
            @@cost_list = @@list.collect { |spell| spell._cost.keys }.flatten
            @@loaded = true
            return true
          rescue
            respond "--- Lich: error: Spell.load: #{$!}"
            Lich.log "error: Spell.load: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
            @@loaded = false
            return false
          end
        }
      end

[Rest of code continues with documentation...]