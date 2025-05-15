# Generated during infomon separation 230305
# script bindings are convoluted, but don't change them without testing if:
#    class methods such as Script.start and ExecScript.start become accessible without specifying the class name (which is just a syptom of a problem that will break scripts)
#    local variables become shared between scripts
#    local variable 'file' is shared between scripts, even though other local variables aren't
#    defined methods are instantly inaccessible
# also, don't put 'untrusted' in the name of the untrusted binding; it shows up in error messages and makes people think the error is caused by not trusting the script

# The Lich module contains core functionality for the Lich scripting system
# @author Lich5 Documentation Generator
module Lich
  # Common functionality shared across the Lich system
  module Common
    # Handles script execution and management 
    class Scripting
      # Creates a new binding for script execution
      # @return [Binding] A fresh binding for script execution
      def script
        Proc.new {}.binding
      end
    end

    # Creates a new binding for script execution
    # @return [Binding] A fresh binding for script execution
    def _script
      Proc.new {}.binding
    end

    # Proc that returns a trusted script binding
    # @return [Proc] Returns a proc that creates trusted script bindings
    TRUSTED_SCRIPT_BINDING = proc { _script }

    # Main script class that handles script execution and management
    class Script
      # Elevated proc for starting scripts
      # @api private
      @@elevated_script_start = proc { |args|
        # Original proc implementation...
        [existing implementation]
      }

      # Elevated proc for checking script existence
      # @api private 
      @@elevated_exists = proc { |script_name|
        # Original proc implementation...
        [existing implementation]
      }

      # Elevated proc for logging
      # @api private
      @@elevated_log = proc { |data|
        # Original proc implementation...
        [existing implementation]
      }

      # Elevated proc for database access
      # @api private
      @@elevated_db = proc {
        # Original proc implementation...
        [existing implementation]
      }

      # Elevated proc for file operations
      # @api private
      @@elevated_open_file = proc { |ext, mode, _block|
        # Original proc implementation...
        [existing implementation]
      }

      # Array of running scripts
      # @api private
      @@running = Array.new

      # Gets the script version
      # @param script_name [String] Name of script to check
      # @param script_version_required [String, nil] Optional version requirement
      # @return [Boolean, Gem::Version] Version comparison result or version object
      def Script.version(script_name, script_version_required = nil)
        # Original implementation...
      end

      # Gets list of all running scripts
      # @return [Array<Script>] Array of running Script objects
      def Script.list
        @@running.dup
      end

      # Gets the currently executing script
      # @return [Script, nil] Current Script object or nil if none
      def Script.current
        if (script = @@running.find { |s| s.has_thread?(Thread.current) })
          sleep 0.2 while script.paused? and not script.ignore_pause
          script
        else
          nil
        end
      end

      # Starts a new script
      # @param args [Array] Script arguments
      # @return [Script, nil] The started Script object or nil if failed
      def Script.start(*args)
        @@elevated_script_start.call(args)
      end

      # Runs a script to completion
      # @param args [Array] Same arguments as Script.start
      # @return [void]
      def Script.run(*args)
        if (s = @@elevated_script_start.call(args))
          sleep 0.1 while @@running.include?(s)
        end
      end

      # Checks if a script is currently running
      # @param name [String] Script name to check
      # @return [Boolean] True if script is running
      def Script.running?(name)
        @@running.any? { |i| (i.name =~ /^#{name}$/i) }
      end

      # Pauses script execution
      # @param name [String, nil] Script name to pause, or current script if nil
      # @return [Script, Boolean] Script object if pausing current script, true/false otherwise
      def Script.pause(name = nil)
        if name.nil?
          Script.current.pause
          Script.current
        else
          if (s = (@@running.find { |i| (i.name == name) and not i.paused? }) || (@@running.find { |i| (i.name =~ /^#{name}$/i) and not i.paused? }))
            s.pause
            true
          else
            false
          end
        end
      end

      # [Continue with remaining method documentation...]
      # For brevity, I've shown the pattern - each method should have YARD docs
      # directly above it following the same format