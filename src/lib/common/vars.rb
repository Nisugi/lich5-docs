# Provides persistent variable storage functionality for the Lich system.
# Variables are stored per game and character in an SQLite database.
#
# @author Lich5 Documentation Generator
module Lich
  module Common
    module Vars
      # Internal hash storing variable values
      # @private
      @@vars   = Hash.new

      # MD5 hash of the variables for change detection
      # @private 
      md5      = nil

      # Flag indicating if variables have been loaded
      # @private
      @@loaded = false

      @@load = proc {
        Lich.db_mutex.synchronize {
          unless @@loaded
            begin
              h = Lich.db.get_first_value('SELECT hash FROM uservars WHERE scope=?;', ["#{XMLData.game}:#{XMLData.name}".encode('UTF-8')])
            rescue SQLite3::BusyException
              sleep 0.1
              retry
            end
            if h
              begin
                hash = Marshal.load(h)
                hash.each { |k, v| @@vars[k] = v }
                md5 = Digest::MD5.hexdigest(hash.to_s)
              rescue
                respond "--- Lich: error: #{$!}"
                respond $!.backtrace[0..2]
              end
            end
            @@loaded = true
          end
        }
        nil
      }

      @@save = proc {
        Lich.db_mutex.synchronize {
          if @@loaded
            if Digest::MD5.hexdigest(@@vars.to_s) != md5
              md5 = Digest::MD5.hexdigest(@@vars.to_s)
              blob = SQLite3::Blob.new(Marshal.dump(@@vars))
              begin
                Lich.db.execute('INSERT OR REPLACE INTO uservars(scope,hash) VALUES(?,?);', ["#{XMLData.game}:#{XMLData.name}".encode('UTF-8'), blob])
              rescue SQLite3::BusyException
                sleep 0.1
                retry
              end
            end
          end
        }
        nil
      }

      Thread.new {
        loop {
          sleep 300
          begin
            @@save.call
          rescue
            Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
            respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
          end
        }
      }

      # Retrieves a stored variable value by name
      #
      # @param name [Object] The variable name/key to lookup
      # @return [Object, nil] The stored value or nil if not found
      # @example
      #   Vars['my_variable'] # => returns stored value
      #   Vars['nonexistent'] # => returns nil
      def Vars.[](name)
        @@load.call unless @@loaded
        @@vars[name]
      end

      # Sets a variable value by name
      #
      # @param name [Object] The variable name/key to set
      # @param val [Object, nil] The value to store. If nil, deletes the variable
      # @return [Object] The stored value
      # @example
      #   Vars['my_var'] = 123
      #   Vars['to_delete'] = nil # Deletes the variable
      def Vars.[]=(name, val)
        @@load.call unless @@loaded
        if val.nil?
          @@vars.delete(name)
        else
          @@vars[name] = val
        end
      end

      # Returns a copy of all stored variables
      #
      # @return [Hash] A duplicate of the internal variables hash
      # @example
      #   all_vars = Vars.list
      #   puts all_vars.inspect
      def Vars.list
        @@load.call unless @@loaded
        @@vars.dup
      end

      # Forces an immediate save of variables to the database
      #
      # @return [nil]
      # @example
      #   Vars.save
      def Vars.save
        @@save.call
      end

      # Provides dynamic getter/setter functionality for variables
      #
      # @param arg1 [Symbol] The method name, interpreted as variable name
      # @param arg2 [Object] The value to set (for setters)
      # @return [Object] The variable value for getters, the assigned value for setters
      # @example Getter usage
      #   Vars.my_variable # => returns value of 'my_variable'
      # @example Setter usage
      #   Vars.new_var = 'value' # Sets 'new_var' to 'value'
      # @note Method names ending with '=' are treated as setters
      def Vars.method_missing(arg1, arg2 = '')
        @@load.call unless @@loaded
        if arg1[-1, 1] == '='
          if arg2.nil?
            @@vars.delete(arg1.to_s.chop)
          else
            @@vars[arg1.to_s.chop] = arg2
          end
        else
          @@vars[arg1.to_s]
        end
      end
    end
  end
end