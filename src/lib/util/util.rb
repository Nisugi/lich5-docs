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

# Core utilities module that extends Lich capabilities with helper methods
# for game interaction and data manipulation.
#
# @author Elanthia-Online
# @version 1.3.1
module Lich
  module Util
    include Enumerable

    # Validates if a given value exists in an effects lookup table
    #
    # @param effect [String] The effect category to check
    # @param val [String, Integer, Symbol] The value to look up
    # @return [Boolean] True if value exists in lookup, false otherwise
    # @raise [RuntimeError] If val is not a String, Integer or Symbol
    # @example
    #   Lich::Util.normalize_lookup("Spells", "Shield")
    #   Lich::Util.normalize_lookup("Buffs", 1001)
    #
    # @note Evaluates against Effects::{effect} namespace
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

    # Normalizes a name string by converting spaces/hyphens to underscores
    # and removing special characters
    #
    # @param name [String, Symbol] The name to normalize
    # @return [String] Normalized name in lowercase with underscores
    # @example
    #   Lich::Util.normalize_name("Predator's Eye") #=> "predators_eye"
    #   Lich::Util.normalize_name("vault-kick") #=> "vault_kick"
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

    # Generates a unique anonymous hook name
    #
    # @param prefix [String] Optional prefix for the hook name
    # @return [String] Unique hook identifier
    # @example
    #   Lich::Util.anon_hook("MyHook") #=> "Util::MyHook-2023-07-14-1234"
    def self.anon_hook(prefix = '')
      now = Time.now
      "Util::#{prefix}-#{now}-#{Random.rand(10000)}"
    end

    # Issues a command and captures output between start and end patterns
    #
    # @param command [String] The command to execute
    # @param start_pattern [Regexp] Pattern indicating start of capture
    # @param end_pattern [Regexp] Pattern indicating end of capture
    # @param include_end [Boolean] Whether to include matching end line
    # @param timeout [Integer] Seconds to wait before timeout
    # @param silent [Boolean] Whether to suppress output
    # @param usexml [Boolean] Whether to use XML mode
    # @param quiet [Boolean] Whether to filter captured lines
    # @param use_fput [Boolean] Whether to use fput vs put
    # @return [Array<String>] Captured lines of output
    # @raise [Interrupt] If timeout occurs
    # @example
    #   Lich::Util.issue_command("look", /^You see/, /^\>/)
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

    # Executes a command silently with XML processing
    #
    # @param command [String] The command to execute
    # @param start_pattern [Regexp] Pattern indicating start of capture
    # @param end_pattern [Regexp] Pattern indicating end of capture
    # @param include_end [Boolean] Whether to include matching end line
    # @param timeout [Integer] Seconds to wait before timeout
    # @param silent [Boolean] Whether to suppress output
    # @return [Array<String>] Captured lines of output
    # @example
    #   Lich::Util.quiet_command_xml("inventory", /^You are/, /^\>/)
    def self.quiet_command_xml(command, start_pattern, end_pattern = /<prompt/, include_end = true, timeout = 5, silent = true)
      return issue_command(command, start_pattern, end_pattern, include_end: include_end, timeout: timeout, silent: silent, usexml: true, quiet: true)
    end

    # Executes a command silently without XML processing
    #
    # @param command [String] The command to execute
    # @param start_pattern [Regexp] Pattern indicating start of capture
    # @param end_pattern [Regexp] Pattern indicating end of capture
    # @param include_end [Boolean] Whether to include matching end line
    # @param timeout [Integer] Seconds to wait before timeout
    # @param silent [Boolean] Whether to suppress output
    # @return [Array<String>] Captured lines of output
    # @example
    #   Lich::Util.quiet_command("health", /^You have/, /^\>/)
    def self.quiet_command(command, start_pattern, end_pattern, include_end = true, timeout = 5, silent = true)
      return issue_command(command, start_pattern, end_pattern, include_end: include_end, timeout: timeout, silent: silent, usexml: false, quiet: true)
    end

    # Gets the current silver count from character info
    #
    # @param timeout [Integer] Seconds to wait before timeout
    # @return [Integer] Amount of silver
    # @example
    #   silver = Lich::Util.silver_count
    #
    # @note Temporarily silences output while checking
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

    # Installs required Ruby gems and optionally requires them
    #
    # @param gems_to_install [Hash{String => Boolean}] Gem names and whether to require them
    # @raise [ArgumentError] If parameter is not a hash of strings to booleans
    # @raise [StandardError] If gem installation fails
    # @example
    #   Lich::Util.install_gem_requirements({
    #     "json" => true,
    #     "nokogiri" => false
    #   })
    #
    # @note Installs gems for user only, without documentation
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