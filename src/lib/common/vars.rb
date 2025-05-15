# Carve out module Vars (should this be in settings path?)
# 2024-06-13

module Lich
  module Common
    module Vars
      @@vars   = Hash.new
      md5      = nil
      @@loaded = false
      
      # Proc to load variables from the database.
      # 
      # @return [NilClass] always returns nil.
      # @raise [SQLite3::BusyException] if the database is busy.
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
      
      # Proc to save variables to the database.
      # 
      # @return [NilClass] always returns nil.
      # @raise [SQLite3::BusyException] if the database is busy.
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
      
      # Thread to periodically save variables to the database every 300 seconds.
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
      
      # Retrieves the value associated with the given name.
      #
      # @param name [String] the name of the variable to retrieve.
      # @return [Object, NilClass] the value associated with the name, or nil if not found.
      def Vars.[](name)
        @@load.call unless @@loaded
        @@vars[name]
      end

      # Sets the value for the given name.
      #
      # @param name [String] the name of the variable to set.
      # @param val [Object, NilClass] the value to assign, or nil to delete the variable.
      # @return [NilClass] always returns nil.
      def Vars.[]=(name, val)
        @@load.call unless @@loaded
        if val.nil?
          @@vars.delete(name)
        else
          @@vars[name] = val
        end
      end

      # Returns a duplicate of the current variables hash.
      #
      # @return [Hash] a duplicate of the variables hash.
      def Vars.list
        @@load.call unless @@loaded
        @@vars.dup
      end

      # Saves the current variables to the database.
      #
      # @return [NilClass] always returns nil.
      def Vars.save
        @@save.call
      end

      # Handles dynamic method calls for getting and setting variables.
      #
      # @param arg1 [Symbol] the name of the variable or the setter method (ending with '=').
      # @param arg2 [Object, NilClass] the value to set if it's a setter method.
      # @return [Object, NilClass] the value of the variable or nil if deleted.
      # @note This method will call @@load if the variables have not been loaded yet.
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
