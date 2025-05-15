=begin
util.rb: Core lich file for collection of utilities to extend Lich capabilities.
Entries added here should always be accessible from Lich::Util.feature namespace.

    Maintainer: Elanthia-Online
    Original Author: LostRanger, Ondreian, various others
    game: Gemstone
    tags: CORE, util, utilities
    required: Lich > 5.0.19
    version: 1.3.1

  changelog:
    v1.3.1 (2022-06-26)
     * Fix to not squelch the end_pattern for issue_command if not a quiet command
    v1.3.0 (2022-03-16)
     * Add Lich::Util.issue_command that allows more fine-tooled control return
     * Bugfix for Lich::Util.silver_count not using end_pattern properly
    v1.2.0 (2022-03-16)
     * Add Lich::Util.quiet_command to mimic XML version
    v1.1.0 (2022-03-09)
     * Fix silver_count forcing downstream_xml on
    v1.0.0 (2022-03-08)
     * Initial release

=end

module Lich
  module Util
    include Enumerable

    # Normalizes the lookup for effects based on the provided value.
    #
    # @param effect [String] The effect type to look up.
    # @param val [String, Integer, Symbol] The value to normalize and check.
    # @return [Boolean] True if the normalized value exists, false otherwise.
    # @raise [RuntimeError] If an invalid lookup case is provided.
    #
    # @example
    #   Lich::Util.normalize_lookup('some_effect', 'some_value')
    def self.normalize_lookup(effect, val)
      caller_type = "Effects::#{effect}"
      case val
      when String
        (eval caller_type).to_h.transform_keys(&:to_s).transform_keys(&:downcase).include?(val.downcase.gsub('_', ' '))
      when Integer
        #      seek = mappings.fetch(val, nil)
        (eval caller_type).active?(val)
      when Symbol
        (eval caller_type).to_h.transform_keys(&:to_s).transform_keys(&:downcase).include?(val.to_s.downcase.gsub('_', ' '))
      else
        fail "invalid lookup case #{val.class.name}"
      end
    end

    # Normalizes a name by converting it to a standard format.
    #
    # @param name [String, Symbol] The name to normalize.
    # @return [String] The normalized name.
    #
    # @example
    #   Lich::Util.normalize_name("vault-kick")
    #   # => "vault_kick"
    def self.normalize_name(name)
      # there are five cases to normalize
      # "vault_kick", "vault kick", "vault-kick", :vault_kick, :vaultkick
      # "predator's eye"
      # if present, convert spaces to underscore; convert all to downcase string
      normal_name = name.to_s.downcase
      normal_name.gsub!(' ', '_') if name =~ (/\s/)
      normal_name.gsub!('-', '_') if name =~ (/-/)
      normal_name.gsub!(":", '') if name =~ (/:/)
      normal_name.gsub!("'", '') if name =~ (/'/)
      normal_name
    end

    ## Lifted from LR foreach.lic

    # Generates an anonymous hook name based on the current time and a random number.
    #
    # @param prefix [String] An optional prefix for the hook name.
    # @return [String] The generated anonymous hook name.
    #
    # @example
    #   Lich::Util.anon_hook("test")
    def self.anon_hook(prefix = '')
      now = Time.now
      "Util::#{prefix}-#{now}-#{Random.rand(10000)}"
    end

    # Issues a command and captures the output between start and end patterns.
    #
    # @param command [String] The command to execute.
    # @param start_pattern [Regexp] The pattern indicating the start of the output to capture.
    # @param end_pattern [Regexp] The pattern indicating the end of the output to capture (default: /<prompt/).
    # @param include_end [Boolean] Whether to include the end line in the result (default: true).
    # @param timeout [Integer] The maximum time to wait for the command to complete (default: 5).
    # @param silent [Boolean, nil] Whether to suppress output (default: nil).
    # @param usexml [Boolean] Whether to use XML output (default: true).
    # @param quiet [Boolean] Whether to suppress output during capture (default: false).
    # @param use_fput [Boolean] Whether to use fput for command execution (default: true).
    # @return [Array<String>] The captured output lines.
    # @raise [Timeout::Error] If the command times out.
    #
    # @example
    #   output = Lich::Util.issue_command("look", /You see/, /<prompt/)
    def self.issue_command(command, start_pattern, end_pattern = /<prompt/, include_end: true, timeout: 5, silent: nil, usexml: true, quiet: false, use_fput: true)
      result = []
      name = self.anon_hook
      filter = false

      save_script_silent = Script.current.silent
      save_want_downstream = Script.current.want_downstream
      save_want_downstream_xml = Script.current.want_downstream_xml

      Script.current.silent = silent if !silent.nil?
      Script.current.want_downstream = !usexml
      Script.current.want_downstream_xml = usexml

      begin
        Timeout::timeout(timeout, Interrupt) {
          DownstreamHook.add(name, proc { |line|
            if filter
              if line =~ end_pattern
                DownstreamHook.remove(name)
                filter = false
                if quiet
                  next(nil)
                else
                  line
                end
              else
                if quiet
                  next(nil)
                else
                  line
                end
              end
            elsif line =~ start_pattern
              filter = true
              if quiet
                next(nil)
              else
                line
              end
            else
              line
            end
          })
          use_fput ? fput(command) : put(command)

          until (line = get) =~ start_pattern; end
          result << line.rstrip
          until (line = get) =~ end_pattern
            result << line.rstrip
          end
          if include_end
            result << line.rstrip
          end
        }
      rescue Interrupt
        nil
      ensure
        DownstreamHook.remove(name)
        Script.current.silent = save_script_silent if !silent.nil?
        Script.current.want_downstream = save_want_downstream
        Script.current.want_downstream_xml = save_want_downstream_xml
      end
      return result
    end

    # Issues a quiet command and captures the output in XML format.
    #
    # @param command [String] The command to execute.
    # @param start_pattern [Regexp] The pattern indicating the start of the output to capture.
    # @param end_pattern [Regexp] The pattern indicating the end of the output to capture (default: /<prompt/).
    # @param include_end [Boolean] Whether to include the end line in the result (default: true).
    # @param timeout [Integer] The maximum time to wait for the command to complete (default: 5).
    # @param silent [Boolean] Whether to suppress output (default: true).
    # @return [Array<String>] The captured output lines.
    #
    # @example
    #   output = Lich::Util.quiet_command_xml("look", /You see/, /<prompt/)
    def self.quiet_command_xml(command, start_pattern, end_pattern = /<prompt/, include_end = true, timeout = 5, silent = true)
      return issue_command(command, start_pattern, end_pattern, include_end: include_end, timeout: timeout, silent: silent, usexml: true, quiet: true)
    end

    # Issues a quiet command and captures the output.
    #
    # @param command [String] The command to execute.
    # @param start_pattern [Regexp] The pattern indicating the start of the output to capture.
    # @param end_pattern [Regexp] The pattern indicating the end of the output to capture.
    # @param include_end [Boolean] Whether to include the end line in the result (default: true).
    # @param timeout [Integer] The maximum time to wait for the command to complete (default: 5).
    # @param silent [Boolean] Whether to suppress output (default: true).
    # @return [Array<String>] The captured output lines.
    #
    # @example
    #   output = Lich::Util.quiet_command("look", /You see/, /<prompt/)
    def self.quiet_command(command, start_pattern, end_pattern, include_end = true, timeout = 5, silent = true)
      return issue_command(command, start_pattern, end_pattern, include_end: include_end, timeout: timeout, silent: silent, usexml: false, quiet: true)
    end

    # Counts the amount of silver and returns it as an integer.
    #
    # @param timeout [Integer] The maximum time to wait for the count (default: 3).
    # @return [Integer] The amount of silver counted.
    # @raise [RuntimeError] If the counting process fails.
    #
    # @example
    #   silver_amount = Lich::Util.silver_count
    def self.silver_count(timeout = 3)
      silence_me unless (undo_silence = silence_me)
      result = ''
      name = self.anon_hook
      filter = false

      start_pattern = /^\s*Name\:/
      end_pattern = /^\s*Mana\:\s+\-?[0-9]+\s+Silver\:\s+([0-9,]+)/
      ttl = Time.now + timeout
      begin
        # main thread
        DownstreamHook.add(name, proc { |line|
          if filter
            if line =~ end_pattern
              result = $1.dup
              DownstreamHook.remove(name)
              filter = false
            else
              next(nil)
            end
          elsif line =~ start_pattern
            filter = true
            next(nil)
          else
            line
          end
        })
        # script thread
        fput 'info'
        loop {
          # non-blocking check, this allows us to
          # check the time even when the buffer is empty
          line = get?
          break if line && line =~ end_pattern
          break if Time.now > ttl
          sleep(0.01) # prevent a tight-loop
        }
      ensure
        DownstreamHook.remove(name)
        silence_me if undo_silence
      end
      return result.gsub(',', '').to_i
    end

    # Installs the specified gems and requires them if specified.
    #
    # @param gems_to_install [Hash] A hash where keys are gem names and values are booleans indicating whether to require them.
    # @raise [ArgumentError] If the input is not a hash or if the hash does not contain valid key-value pairs.
    # @raise [RuntimeError] If any gem installation fails.
    #
    # @example
    #   Lich::Util.install_gem_requirements({"some_gem" => true})
    def self.install_gem_requirements(gems_to_install)
      raise ArgumentError, "install_gem_requirements must be passed a Hash" unless gems_to_install.is_a?(Hash)
      require "rubygems"
      require "rubygems/dependency_installer"
      installer = Gem::DependencyInstaller.new({ :user_install => true, :document => nil })
      installed_gems = Gem::Specification.map { |gem| gem.name }.sort.uniq
      failed_gems = []

      gems_to_install.each do |gem_name, should_require|
        unless gem_name.is_a?(String) && (should_require.is_a?(TrueClass) || should_require.is_a?(FalseClass))
          raise ArgumentError, "install_gem_requirements must be passed a Hash with String key and TrueClass/FalseClass as value"
        end
        begin
          unless installed_gems.include?(gem_name)
            respond("--- Lich: Installing missing ruby gem '#{gem_name}' now, please wait!")
            installer.install(gem_name)
            respond("--- Lich: Done installing '#{gem_name}' gem!")
          end
          require gem_name if should_require
        rescue StandardError
          respond("--- Lich: error: Failed to install Ruby gem: #{gem_name}")
          respond("--- Lich: error: #{$!}")
          Lich.log("error: Failed to install Ruby gem: #{gem_name}")
          Lich.log("error: #{$!}")
          failed_gems.push(gem_name)
        end
      end
      unless failed_gems.empty?
        raise("Please install the failed gems: #{failed_gems.join(', ')} to run #{$lich_char}#{Script.current.name}")
      end
    end
  end
end