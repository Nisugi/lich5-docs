# global_defs carveout for lich5
# this needs to be broken up even more - OSXLich-Doug (2022-04-13)
# rubocop changes and DR toplevel command handling (2023-06-28)
# sadly adding global level script methods (2024-06-12)

# added 2024

# Starts a script with the given name and optional command line variables and flags.
#
# @param script_name [String] The name of the script to start.
# @param cli_vars [Array<String>] Optional command line variables to pass to the script.
# @param flags [Hash] Optional flags for script execution. If set to true, defaults to { :quiet => true }.
# @return [void]
# @example
#   start_script("my_script", ["--option1", "value1"], { :verbose => true })
def start_script(script_name, cli_vars = [], flags = Hash.new)
  if flags == true
    flags = { :quiet => true }
  end
  Script.start(script_name, cli_vars.join(' '), flags)
end

# Starts multiple scripts sequentially.
#
# @param script_names [Array<String>] The names of the scripts to start.
# @return [void]
# @example
#   start_scripts("script1", "script2")
def start_scripts(*script_names)
  script_names.flatten.each { |script_name|
    start_script(script_name)
    sleep 0.02
  }
end

# Forces the start of a script, ensuring it runs even if it is already running.
#
# @param script_name [String] The name of the script to force start.
# @param cli_vars [Array<String>] Optional command line variables to pass to the script.
# @param flags [Hash] Optional flags for script execution.
# @return [void]
# @example
#   force_start_script("my_script", ["--force"], { :debug => true })
def force_start_script(script_name, cli_vars = [], flags = {})
  flags = Hash.new unless flags.class == Hash
  flags[:force] = true
  start_script(script_name, cli_vars, flags)
end

# Registers a block of code to be executed when the script is exiting.
#
# @param code [Proc] The block of code to execute on exit.
# @return [void]
# @example
#   before_dying { puts "Script is exiting." }
def before_dying(&code)
  Script.at_exit(&code)
end

# Clears any previously registered exit procedures.
#
# @return [void]
# @example
#   undo_before_dying
def undo_before_dying
  Script.clear_exit_procs
end

# Aborts the current script execution.
#
# @return [void]
# @example
#   abort!
def abort!
  Script.exit!
end

# Stops the specified scripts by name.
#
# @param target_names [Array<String>] The names of the scripts to stop.
# @return [Integer, false] The number of scripts killed, or false if none were killed.
# @example
#   stop_script("script1", "script2")
def stop_script(*target_names)
  numkilled = 0
  target_names.each { |target_name|
    condemned = Script.list.find { |s_sock| s_sock.name =~ /^#{target_name}/i }
    if condemned.nil?
      respond("--- Lich: '#{Script.current}' tried to stop '#{target_name}', but it isn't running!")
    else
      if condemned.name =~ /^#{Script.current.name}$/i
        exit
      end
      condemned.kill
      respond("--- Lich: '#{condemned}' has been stopped by #{Script.current}.")
      numkilled += 1
    end
  }
  if numkilled == 0
    return false
  else
    return numkilled
  end
end

# Checks if the specified scripts are currently running.
#
# @param snames [Array<String>] The names of the scripts to check.
# @return [Boolean] True if all specified scripts are running, false otherwise.
# @example
#   running?("script1", "script2")
def running?(*snames)
  snames.each { |checking| (return false) unless (Script.running.find { |lscr| lscr.name =~ /^#{checking}$/i } || Script.running.find { |lscr| lscr.name =~ /^#{checking}/i } || Script.hidden.find { |lscr| lscr.name =~ /^#{checking}$/i } || Script.hidden.find { |lscr| lscr.name =~ /^#{checking}/i }) }
  true
end

# Starts an execution script with the given command data and options.
#
# @param cmd_data [String] The command data to execute.
# @param options [Hash] Optional execution options.
# @return [void]
# @example
#   start_exec_script("some_command", { timeout: 30 })
def start_exec_script(cmd_data, options = Hash.new)
  ExecScript.start(cmd_data, options)
end

# Toggles the visibility of the current script.
#
# @return [void]
# @note This method is intended for use prior to 2024.
# @example
#   hide_me
def hide_me
  Script.current.hidden = !Script.current.hidden
end

# Toggles the no_kill_all setting for the current script.
#
# @return [void]
# @example
#   no_kill_all
def no_kill_all
  script = Script.current
  script.no_kill_all = !script.no_kill_all
end

# Toggles the no_pause_all setting for the current script.
#
# @return [void]
# @example
#   no_pause_all
def no_pause_all
  script = Script.current
  script.no_pause_all = !script.no_pause_all
end

# Toggles the upstream setting for the current script.
#
# @return [void, nil] Returns nil if the script cannot be identified.
# @example
#   toggle_upstream
def toggle_upstream
  unless (script = Script.current) then echo 'toggle_upstream: cannot identify calling script.'; return nil; end
  script.want_upstream = !script.want_upstream
end

# Toggles the silent mode for the current script.
#
# @return [Boolean, nil] Returns true if the script is safe and the request is ignored, nil if the script cannot be identified.
# @example
#   silence_me
def silence_me
  unless (script = Script.current) then echo 'silence_me: cannot identify calling script.'; return nil; end
  if script.safe? then echo("WARNING: 'safe' script attempted to silence itself.  Ignoring the request.")
                       sleep 1
                       return true
  end
  script.silent = !script.silent
end

# Toggles the echo setting for the current script.
#
# @return [void, nil] Returns nil if the script cannot be identified.
# @example
#   toggle_echo
def toggle_echo
  unless (script = Script.current) then respond('--- toggle_echo: Unable to identify calling script.'); return nil; end
  script.no_echo = !script.no_echo
end

# Turns on echo for the current script.
#
# @return [void, nil] Returns nil if the script cannot be identified.
# @example
#   echo_on
def echo_on
  unless (script = Script.current) then respond('--- echo_on: Unable to identify calling script.'); return nil; end
  script.no_echo = false
end

# Turns off echo for the current script.
#
# @return [void, nil] Returns nil if the script cannot be identified.
# @example
#   echo_off
def echo_off
  unless (script = Script.current) then respond('--- echo_off: Unable to identify calling script.'); return nil; end
  script.no_echo = true
end

# Retrieves upstream data for the current script.
#
# @return [Boolean, nil] Returns false if the script is not set to receive upstream, nil if the script cannot be identified.
# @example
#   upstream_get
def upstream_get
  unless (script = Script.current) then echo 'upstream_get: cannot identify calling script.'; return nil; end
  unless script.want_upstream
    echo("This script wants to listen to the upstream, but it isn't set as receiving the upstream! This will cause a permanent hang, aborting (ask for the upstream with 'toggle_upstream' in the script)")
    sleep 0.3
    return false
  end
  script.upstream_gets
end

# Checks if the current script is set to receive upstream data.
#
# @return [Boolean, nil] Returns false if the script is not set to receive upstream, nil if the script cannot be identified.
# @example
#   upstream_get?
def upstream_get?
  unless (script = Script.current) then echo 'upstream_get: cannot identify calling script.'; return nil; end
  unless script.want_upstream
    echo("This script wants to listen to the upstream, but it isn't set as receiving the upstream! This will cause a permanent hang, aborting (ask for the upstream with 'toggle_upstream' in the script)")
    return false
  end
  script.upstream_gets?
end

# Sends messages to the current script's response handler.
#
# @param messages [Array<String>] The messages to send.
# @return [nil]
# @example
#   echo("Hello, World!")
def echo(*messages)
  respond if messages.empty?
  if (script = Script.current)
    unless script.no_echo
      messages.each { |message| respond("[#{script.name}: #{message.to_s.chomp}]") }
    end
  else
    messages.each { |message| respond("[(unknown script): #{message.to_s.chomp}]") }
  end
  nil
end

# Sends messages to the current script's response handler, using a different response method.
#
# @param messages [Array<String>] The messages to send.
# @return [nil]
# @example
#   _echo("Hidden message")
def _echo(*messages)
  _respond if messages.empty?
  if (script = Script.current)
    unless script.no_echo
      messages.each { |message| _respond("[#{script.name}: #{message.to_s.chomp}]") }
    end
  else
    messages.each { |message| _respond("[(unknown script): #{message.to_s.chomp}]") }
  end
  nil
end

# Jumps to a specified label in the current script.
#
# @param label [String] The label to jump to.
# @return [void]
# @raise [JUMP] Raises a JUMP exception to indicate a jump.
# @example
#   goto("my_label")
def goto(label)
  Script.current.jump_label = label.to_s
  raise JUMP
end

# Pauses the specified scripts by name.
#
# @param names [Array<String>] The names of the scripts to pause.
# @return [void]
# @example
#   pause_script("script1", "script2")
def pause_script(*names)
  names.flatten!
  if names.empty?
    Script.current.pause
    Script.current
  else
    names.each { |scr|
      fnd = Script.list.find { |nm| nm.name =~ /^#{scr}/i }
      fnd.pause unless (fnd.paused || fnd.nil?)
    }
  end
end

# Unpauses the specified scripts by name.
#
# @param names [Array<String>] The names of the scripts to unpause.
# @return [void]
# @example
#   unpause_script("script1", "script2")
def unpause_script(*names)
  names.flatten!
  names.each { |scr|
    fnd = Script.list.find { |nm| nm.name =~ /^#{scr}/i }
    fnd.unpause if (fnd.paused and not fnd.nil?)
  }
end

# Fixes the injury mode in the game if it is not set to 2.
#
# @return [void]
# @example
#   fix_injury_mode
def fix_injury_mode
  unless XMLData.injury_mode == 2
    Game._puts '_injury 2'
    150.times { sleep 0.05; break if XMLData.injury_mode == 2 }
  end
end

# Hides or shows the specified scripts by name.
#
# @param args [Array<String>] The names of the scripts to hide/show.
# @return [void]
# @example
#   hide_script("script1", "script2")
def hide_script(*args)
  args.flatten!
  args.each { |name|
    if (script = Script.running.find { |scr| scr.name == name })
      script.hidden = !script.hidden
    end
  }
end

# Parses a string into a list.
#
# @param string [String] The string to parse.
# @return [Array<String>] The parsed list.
# @example
#   parse_list("item1, item2, item3")
def parse_list(string)
  string.split_as_list
end

# Waits for roundtime to complete.
#
# @return [void]
# @example
#   waitrt
def waitrt
  wait_until { (XMLData.roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f) > 0 }
  sleep checkrt
end

# Waits for cast roundtime to complete.
#
# @return [void]
# @example
#   waitcastrt
def waitcastrt
  wait_until { (XMLData.cast_roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f) > 0 }
  sleep checkcastrt
end

# Checks the remaining roundtime.
#
# @return [Float] The remaining roundtime, or 0 if none.
# @example
#   remaining_time = checkrt
def checkrt
  [0, XMLData.roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f].max
end

# Checks the remaining cast roundtime.
#
# @return [Float] The remaining cast roundtime, or 0 if none.
# @example
#   remaining_cast_time = checkcastrt
def checkcastrt
  [0, XMLData.cast_roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f].max
end

# Waits for roundtime to complete and returns whether it was successful.
#
# @return [Boolean] True if roundtime was waited for, false if it was already complete.
# @example
#   success = waitrt?
def waitrt?
  sleep checkrt
  return true if checkrt > 0.0
  return false if checkrt == 0
end

# Waits for cast roundtime to complete and returns whether it was successful.
#
# @return [Boolean] True if cast roundtime was waited for, false if it was already complete.
# @example
#   success = waitcastrt?
def waitcastrt?
  #  sleep checkcastrt
  current_castrt = checkcastrt
  if current_castrt.to_f > 0.0
    sleep(current_castrt)
    return true
  else
    return false
  end
end

# Checks if the character is poisoned.
# 
# @return [Boolean] true if the character is poisoned, false otherwise.
# @example
#   checkpoison # => true or false
def checkpoison
  XMLData.indicator['IconPOISONED'] == 'y'
end

# Checks if the character is diseased.
# 
# @return [Boolean] true if the character is diseased, false otherwise.
# @example
#   checkdisease # => true or false
def checkdisease
  XMLData.indicator['IconDISEASED'] == 'y'
end

# Checks if the character is sitting.
# 
# @return [Boolean] true if the character is sitting, false otherwise.
# @example
#   checksitting # => true or false
def checksitting
  XMLData.indicator['IconSITTING'] == 'y'
end

# Checks if the character is kneeling.
# 
# @return [Boolean] true if the character is kneeling, false otherwise.
# @example
#   checkkneeling # => true or false
def checkkneeling
  XMLData.indicator['IconKNEELING'] == 'y'
end

# Checks if the character is stunned.
# 
# @return [Boolean] true if the character is stunned, false otherwise.
# @example
#   checkstunned # => true or false
def checkstunned
  XMLData.indicator['IconSTUNNED'] == 'y'
end

# Checks if the character is bleeding.
# 
# @return [Boolean] true if the character is bleeding, false otherwise.
# @example
#   checkbleeding # => true or false
def checkbleeding
  XMLData.indicator['IconBLEEDING'] == 'y'
end

# Checks if the character is grouped.
# 
# @return [Boolean] true if the character is grouped, false otherwise.
# @example
#   checkgrouped # => true or false
def checkgrouped
  XMLData.indicator['IconJOINED'] == 'y'
end

# Checks if the character is dead.
# 
# @return [Boolean] true if the character is dead, false otherwise.
# @example
#   checkdead # => true or false
def checkdead
  XMLData.indicator['IconDEAD'] == 'y'
end

# Checks if the character is really bleeding, considering active spells.
# 
# @return [Boolean] true if the character is really bleeding, false otherwise.
# @example
#   checkreallybleeding # => true or false
def checkreallybleeding
  checkbleeding and !(Spell[9909].active? or Spell[9905].active?)
end

# Checks if the character is muckled based on the game type.
# 
# @return [Boolean] true if the character is muckled, false otherwise.
# @note This method requires a better DR solution.
# @example
#   muckled? # => true or false
def muckled?
  # need a better DR solution
  if XMLData.game =~ /GS/
    return Status.muckled?
  else
    return checkdead || checkstunned || checkwebbed
  end
end

# Checks if the character is hidden.
# 
# @return [Boolean] true if the character is hidden, false otherwise.
# @example
#   checkhidden # => true or false
def checkhidden
  XMLData.indicator['IconHIDDEN'] == 'y'
end

# Checks if the character is invisible.
# 
# @return [Boolean] true if the character is invisible, false otherwise.
# @example
#   checkinvisible # => true or false
def checkinvisible
  XMLData.indicator['IconINVISIBLE'] == 'y'
end

# Checks if the character is webbed.
# 
# @return [Boolean] true if the character is webbed, false otherwise.
# @example
#   checkwebbed # => true or false
def checkwebbed
  XMLData.indicator['IconWEBBED'] == 'y'
end

# Checks if the character is prone.
# 
# @return [Boolean] true if the character is prone, false otherwise.
# @example
#   checkprone # => true or false
def checkprone
  XMLData.indicator['IconPRONE'] == 'y'
end

# Checks if the character is not standing.
# 
# @return [Boolean] true if the character is not standing, false otherwise.
# @example
#   checknotstanding # => true or false
def checknotstanding
  XMLData.indicator['IconSTANDING'] == 'n'
end

# Checks if the character is standing.
# 
# @return [Boolean] true if the character is standing, false otherwise.
# @example
#   checkstanding # => true or false
def checkstanding
  XMLData.indicator['IconSTANDING'] == 'y'
end

# Checks if the character's name matches any of the provided strings.
# 
# @param strings [Array<String>] the names to check against.
# @return [Boolean, String] true if a match is found, otherwise the character's name.
# @example
#   checkname('Hero', 'Villain') # => true or false
def checkname(*strings)
  strings.flatten!
  if strings.empty?
    XMLData.name
  else
    XMLData.name =~ /^(?:#{strings.join('|')})/i
  end
end

# Collects the loot items from the game object.
# 
# @return [Array<String>] an array of loot item nouns.
# @example
#   checkloot # => ["gold", "sword"]
def checkloot
  GameObj.loot.collect { |item| item.noun }
end

# Toggles the downstream setting for the current script.
# 
# @return [Boolean, nil] true if toggled, nil if the script cannot be identified.
# @example
#   i_stand_alone # => true or false
def i_stand_alone
  unless (script = Script.current) then echo 'i_stand_alone: cannot identify calling script.'; return nil; end
  script.want_downstream = !script.want_downstream
  return !script.want_downstream
end

# Outputs debug information if debugging is enabled.
# 
# @param args [Array] the arguments to output.
# @yield [Array] if a block is given, yields the arguments to the block.
# @example
#   debug("Debug message") { |msg| puts msg }
def debug(*args)
  if $LICH_DEBUG
    if block_given?
      yield(*args)
    else
      echo(*args)
    end
  end
end

# Times the execution of provided code blocks.
# 
# @param contestants [Array<Proc>] the code blocks to time.
# @return [Array<Float>] an array of execution times for each block.
# @example
#   timetest(-> { sleep(1) }) # => [1.0]
def timetest(*contestants)
  contestants.collect { |code| start = Time.now; 5000.times { code.call }; Time.now - start }
end

# Converts a decimal number to a binary string.
# 
# @param n [Integer] the decimal number to convert.
# @return [String] the binary representation of the number.
# @example
#   dec2bin(10) # => "1010"
def dec2bin(n)
  "0" + [n].pack("N").unpack("B32")[0].sub(/^0+(?=\d)/, '')
end

# Converts a binary string to a decimal number.
# 
# @param n [String] the binary string to convert.
# @return [Integer] the decimal representation of the binary string.
# @example
#   bin2dec("1010") # => 10
def bin2dec(n)
  [("0" * 32 + n.to_s)[-32..-1]].pack("B32").unpack("N")[0]
end

# Checks if the character has been idle for a specified time.
# 
# @param time [Integer] the idle time in seconds (default is 60).
# @return [Boolean] true if idle for the specified time, false otherwise.
# @example
#   idle?(120) # => true or false
def idle?(time = 60)
  Time.now - $_IDLETIMESTAMP_ >= time
end

# Sends a command and waits for a response, handling success and failure cases.
# 
# @param string [String] the command to send.
# @param success [Array<String>] the success responses.
# @param failure [Array<String>] the failure responses.
# @param timeout [Numeric, nil] the timeout in seconds (optional).
# @raise [ArgumentError] if the arguments are not of the expected types.
# @return [String, nil] the response string on success, nil on failure.
# @example
#   selectput("command", ["success"], ["failure"], 5) # => "response"
def selectput(string, success, failure, timeout = nil)
  timeout = timeout.to_f if timeout and !timeout.kind_of?(Numeric)
  success = [success] if success.kind_of? String
  failure = [failure] if failure.kind_of? String
  if !string.kind_of?(String) or !success.kind_of?(Array) or !failure.kind_of?(Array) or timeout && !timeout.kind_of?(Numeric)
    raise ArgumentError, "usage is: selectput(game_command,success_array,failure_array[,timeout_in_secs])"
  end

  success.flatten!
  failure.flatten!
  regex = /#{(success + failure).join('|')}/i
  successre = /#{success.join('|')}/i
  thr = Thread.current

  timethr = Thread.new {
    timeout -= sleep("0.1".to_f) until timeout <= 0
    thr.raise(StandardError)
  } if timeout

  begin
    loop {
      fput(string)
      response = waitforre(regex)
      if successre.match(response.to_s)
        timethr.kill if timethr.alive?
        break(response.string)
      end
      yield(response.string) if block_given?
    }
  rescue
    nil
  end
end

# Toggles the unique downstream setting for the current script.
# 
# @return [nil] always returns nil.
# @example
#   toggle_unique # => nil
def toggle_unique
  unless (script = Script.current) then echo 'toggle_unique: cannot identify calling script.'; return nil; end
  script.want_downstream = !script.want_downstream
end

# Registers scripts to die with the current script.
# 
# @param vals [Array] the scripts to register.
# @return [nil] always returns nil.
# @example
#   die_with_me("script1", "script2") # => nil
def die_with_me(*vals)
  unless (script = Script.current) then echo 'die_with_me: cannot identify calling script.'; return nil; end
  script.die_with.push vals
  script.die_with.flatten!
  echo("The following script(s) will now die when I do: #{script.die_with.join(', ')}") unless script.die_with.empty?
end

# Waits for a line from the upstream that matches any of the provided strings.
# 
# @param strings [Array<String>] the strings to match against.
# @return [String, false] the matching line or false if not set to receive upstream.
# @example
#   upstream_waitfor("pattern1", "pattern2") # => "matched line" or false
def upstream_waitfor(*strings)
  strings.flatten!
  script = Script.current
  unless script.want_upstream then echo("This script wants to listen to the upstream, but it isn't set as receiving the upstream! This will cause a permanent hang, aborting (ask for the upstream with 'toggle_upstream' in the script)"); return false end
  regexpstr = strings.join('|')
  while (line = script.upstream_gets)
    if line =~ /#{regexpstr}/i
      return line
    end
  end
end

# Sends values to a script that matches the first value.
# 
# @param values [Array] the values to send, where the first value is the script name.
# @return [Boolean] true if sent successfully, false otherwise.
# @example
#   send_to_script("script_name", "value1", "value2") # => true or false
def send_to_script(*values)
  values.flatten!
  if (script = Script.list.find { |val| val.name =~ /^#{values.first}/i })
    if script.want_downstream
      values[1..-1].each { |val| script.downstream_buffer.push(val) }
    else
      values[1..-1].each { |val| script.unique_buffer.push(val) }
    end
    echo("Sent to #{script.name} -- '#{values[1..-1].join(' ; ')}'")
    return true
  else
    echo("'#{values.first}' does not match any active scripts!")
    return false
  end
end

# Sends unique values to a script that matches the first value.
# 
# @param values [Array] the values to send, where the first value is the script name.
# @return [Boolean] true if sent successfully, false otherwise.
# @example
#   unique_send_to_script("script_name", "value1", "value2") # => true or false
def unique_send_to_script(*values)
  values.flatten!
  if (script = Script.list.find { |val| val.name =~ /^#{values.first}/i })
    values[1..-1].each { |val| script.unique_buffer.push(val) }
    echo("sent to #{script}: #{values[1..-1].join(' ; ')}")
    return true
  else
    echo("'#{values.first}' does not match any active scripts!")
    return false
  end
end

# Waits for a unique line from the current script's unique input.
# 
# @param strings [Array<String>] the strings to match against.
# @return [String] the matching line.
# @example
#   unique_waitfor("pattern1", "pattern2") # => "matched line"
def unique_waitfor(*strings)
  unless (script = Script.current) then echo 'unique_waitfor: cannot identify calling script.'; return nil; end
  strings.flatten!
  regexp = /#{strings.join('|')}/
  while true
    str = script.unique_gets
    if str =~ regexp
      return str
    end
  end
end

# Retrieves a unique line from the current script's unique input.
# 
# @return [String, nil] the unique line or nil if the script cannot be identified.
# @example
#   unique_get # => "unique line"
def unique_get
  unless (script = Script.current) then echo 'unique_get: cannot identify calling script.'; return nil; end
  script.unique_gets
end

# Checks if there is a unique line available from the current script's unique input.
# 
# @return [Boolean, nil] true if a unique line is available, nil if the script cannot be identified.
# @example
#   unique_get? # => true or false
def unique_get?
  unless (script = Script.current) then echo 'unique_get: cannot identify calling script.'; return nil; end
  script.unique_gets?
end

# Moves the character in the specified directions.
# 
# @param dirs [Array<String>] A list of directions to move in.
# @return [void]
# @example
#   multimove('north', 'east')
def multimove(*dirs)
  dirs.flatten.each { |dir| move(dir) }
end

# @return [String] The string 'north'.
def n;    'north';     end

# @return [String] The string 'northeast'.
def ne;   'northeast'; end

# @return [String] The string 'east'.
def e;    'east';      end

# @return [String] The string 'southeast'.
def se;   'southeast'; end

# @return [String] The string 'south'.
def s;    'south';     end

# @return [String] The string 'southwest'.
def sw;   'southwest'; end

# @return [String] The string 'west'.
def w;    'west';      end

# @return [String] The string 'northwest'.
def nw;   'northwest'; end

# @return [String] The string 'up'.
def u;    'up';        end

# @return [String] The string 'up'.
def up;   'up'; end

# @return [String] The string 'down'.
def down; 'down';      end

# @return [String] The string 'down'.
def d;    'down';      end

# @return [String] The string 'out'.
def o;    'out';       end

# @return [String] The string 'out'.
def out;  'out';       end

# Moves the character in the specified direction.
#
# @param dir [String] The direction to move in. Defaults to 'none'.
# @param giveup_seconds [Integer] The number of seconds to wait before giving up. Defaults to 10.
# @param giveup_lines [Integer] The number of lines to wait before giving up. Defaults to 30.
# @return [Boolean, nil] Returns false if the move fails, nil if the direction shouldn't be removed from the map database, or true if the move is successful.
# @note This method handles various scenarios and responses from the game environment.
# @example
#   move('north', 10, 30)
def move(dir = 'none', giveup_seconds = 10, giveup_lines = 30)
  # [LNet]-[Private]-Casis: "You begin to make your way up the steep headland pathway.  Before traveling very far, however, you lose your footing on the loose stones.  You struggle in vain to maintain your balance, then find yourself falling to the bay below!"  (20:35:36)
  # [LNet]-[Private]-Casis: "You smack into the water with a splash and sink far below the surface."  (20:35:50)
  # You approach the entrance and identify yourself to the guard.  The guard checks over a long scroll of names and says, "I'm sorry, the Guild is open to invitees only.  Please do return at a later date when we will be open to the public."
  if dir == 'none'
    echo 'move: no direction given'
    return false
  end

  need_full_hands = false
  tried_open = false
  tried_fix_drag = false
  line_count = 0
  room_count = XMLData.room_count
  giveup_time = Time.now.to_i + giveup_seconds.to_i
  save_stream = Array.new

  put_dir = proc {
    if XMLData.room_count > room_count
      fill_hands if need_full_hands
      Script.current.downstream_buffer.unshift(save_stream)
      Script.current.downstream_buffer.flatten!
      return true
    end
    waitrt?
    wait_while { stunned? }
    giveup_time = Time.now.to_i + giveup_seconds.to_i
    line_count = 0
    save_stream.push(clear)
    put dir
  }

  put_dir.call

  loop {
    line = get?
    unless line.nil?
      save_stream.push(line)
      line_count += 1
    end
    if line.nil?
      sleep 0.1
    elsif line =~ /^You realize that would be next to impossible while in combat.|^You can't do that while engaged!|^You are engaged to |^You need to retreat out of combat first!|^You try to move, but you're engaged|^While in combat\?  You'll have better luck if you first retreat/
      # DragonRealms
      fput 'retreat'
      fput 'retreat'
      put_dir.call
    elsif line =~ /^You can't enter .+ and remain hidden or invisible\.|if he can't see you!$|^You can't enter .+ when you can't be seen\.$|^You can't do that without being seen\.$|^How do you intend to get .*? attention\?  After all, no one can see you right now\.$/
      fput 'unhide'
      put_dir.call
    elsif (line =~ /^You (?:take a few steps toward|trudge up to|limp towards|march up to|sashay gracefully up to|skip happily towards|sneak up to|stumble toward) a rusty doorknob/) and (dir =~ /door/)
      which = ['first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh', 'eight', 'ninth', 'tenth', 'eleventh', 'twelfth']
      # avoid stomping the room for the entire session due to a transient failure
      dir = dir.to_s
      if dir =~ /\b#{which.join('|')}\b/
        dir.sub!(/\b(#{which.join('|')})\b/) { "#{which[which.index($1) + 1]}" }
      else
        dir.sub!('door', 'second door')
      end
      put_dir.call
    elsif line =~ /^You can't go there|^You can't (?:go|swim) in that direction\.|^Where are you trying to go\?|^What were you referring to\?|^I could not find what you were referring to\.|^How do you plan to do that here\?|^You take a few steps towards|^You cannot do that\.|^You settle yourself on|^You shouldn't annoy|^You can't go to|^That's probably not a very good idea|^Maybe you should look|^You are already(?! as far away as you can get)|^You walk over to|^You step over to|The [\w\s]+ is too far away|You may not pass\.|become impassable\.|prevents you from entering\.|Please leave promptly\.|is too far above you to attempt that\.$|^Uh, yeah\.  Right\.$|^Definitely NOT a good idea\.$|^Your attempt fails|^There doesn't seem to be any way to do that at the moment\.$/
      echo 'move: failed'
      fill_hands if need_full_hands
      Script.current.downstream_buffer.unshift(save_stream)
      Script.current.downstream_buffer.flatten!
      return false
    elsif line =~ /^[A-z\s-] is unable to follow you\.$|^An unseen force prevents you\.$|^Sorry, you aren't allowed to enter here\.|^That looks like someplace only performers should go\.|^As you climb, your grip gives way and you fall down|^The clerk stops you from entering the partition and says, "I'll need to see your ticket!"$|^The guard stops you, saying, "Only members of registered groups may enter the Meeting Hall\.  If you'd like to visit, ask a group officer for a guest pass\."$|^An? .*? reaches over and grasps [A-Z][a-z]+ by the neck preventing (?:him|her) from being dragged anywhere\.$|^You'll have to wait, [A-Z][a-z]+ .* locker|^As you move toward the gate, you carelessly bump into the guard|^You attempt to enter the back of the shop, but a clerk stops you.  "Your reputation precedes you!|you notice that thick beams are placed across the entry with a small sign that reads, "Abandoned\."$|appears to be closed, perhaps you should try again later\?$/
      echo 'move: failed'
      fill_hands if need_full_hands
      Script.current.downstream_buffer.unshift(save_stream)
      Script.current.downstream_buffer.flatten!
      # return nil instead of false to show the direction shouldn't be removed from the map database
      return nil
    elsif line =~ /^You grab [A-Z][a-z]+ and try to drag h(?:im|er), but s?he (?:is too heavy|doesn't budge)\.$|^Tentatively, you attempt to swim through the nook\.  After only a few feet, you begin to sink!  Your lungs burn from lack of air, and you begin to panic!  You frantically paddle back to safety!$|^Guards(?:wo)?man [A-Z][a-z]+ stops you and says, "(?:Stop\.|Halt!)  You need to make sure you check in|^You step into the root, but can see no way to climb the slippery tendrils inside\.  After a moment, you step back out\.$|^As you start .*? back to safe ground\.$|^You stumble a bit as you try to enter the pool but feel that your persistence will pay off\.$|^A shimmering field of magical crimson and gold energy flows through the area\.$|^You attempt to navigate your way through the fog, but (?:quickly become entangled|get turned around)|^Trying to judge the climb, you peer over the edge\.\s*A wave of dizziness hits you, and you back away from the .*\.$|^You approach the .*, but the steepness is intimidating\.$|^You make your way (?:up|down) the .*\.\s*Partway (?:up|down), you make the mistake of looking down\. Struck by vertigo, you cling to the .* for a few moments, then slowly climb back (?:up|down)\.$|^You pick your way up the .*, but reach a point where your footing is questionable.\s*Reluctantly, you climb back down.$/
      sleep 1
      waitrt?
      put_dir.call
    elsif line =~ /^Climbing.*(?:plunge|fall)|^Tentatively, you attempt to climb.*(?:fall|slip)|^You start up the .* but slip after a few feet and fall to the ground|^You start.*but quickly realize|^You.*drop back to the ground|^You leap .* fall unceremoniously to the ground in a heap\.$|^You search for a way to make the climb .*? but without success\.$|^You start to climb .* you fall to the ground|^You attempt to climb .* wrong approach|^You run towards .*? slowly retreat back, reassessing the situation\.|^You attempt to climb down the .*, but you can't seem to find purchase\.|^You start down the .*, but you find it hard going.\s*Rather than risking a fall, you make your way back up\./
      sleep 1
      waitrt?
      fput 'stand' unless standing?
      waitrt?
      put_dir.call
    elsif line =~ /^You begin to climb up the silvery thread.* you tumble to the ground/
      sleep 0.5
      waitrt?
      fput 'stand' unless standing?
      waitrt?
      if checkleft or checkright
        need_full_hands = true
        empty_hands
      end
      put_dir.call
    elsif line == 'You are too injured to be doing any climbing!'
      if (resolve = Spell[9704]) and resolve.known?
        wait_until { resolve.affordable? }
        resolve.cast
        put_dir.call
      else
        return nil
      end
    elsif line =~ /^You(?:'re going to| will) have to climb that\./
      dir.gsub!('go', 'climb')
      put_dir.call
    elsif line =~ /^You can't climb that\./
      dir.gsub!('climb', 'go')
      put_dir.call
    elsif line =~ /^You can't drag/
      if tried_fix_drag
        fill_hands if need_full_hands
        Script.current.downstream_buffer.unshift(save_stream)
        Script.current.downstream_buffer.flatten!
        return false
      elsif (dir =~ /^(?:go|climb) .+$/) and (drag_line = reget.reverse.find { |l| l =~ /^You grab .*?(?:'s body)? and drag|^You are now automatically attempting to drag .*? when/ })
        tried_fix_drag = true
        name = (/^You grab (.*?)('s body)? and drag/.match(drag_line).captures.first || /^You are now automatically attempting to drag (.*?) when/.match(drag_line).captures.first)
        target = /^(?:go|climb) (.+)$/.match(dir).captures.first
        fput "drag #{name}"
        dir = "drag #{name} #{target}"
        put_dir.call
      else
        tried_fix_drag = true
        dir.sub!(/^climb /, 'go ')
        put_dir.call
      end
    elsif line =~ /^Maybe if your hands were empty|^You figure freeing up both hands might help\.|^You can't .+ with your hands full\.$|^You'll need empty hands to climb that\.$|^It's a bit too difficult to swim holding|^You will need both hands free for such a difficult task\./
      need_full_hands = true
      empty_hands
      put_dir.call
    elsif line =~ /(?:appears|seems) to be closed\.$|^You cannot quite manage to squeeze between the stone doors\.$/
      if tried_open
        fill_hands if need_full_hands
        Script.current.downstream_buffer.unshift(save_stream)
        Script.current.downstream_buffer.flatten!
        return false
      else
        tried_open = true
        fput dir.sub(/go|climb/, 'open')
        put_dir.call
      end
    elsif line =~ /^(\.\.\.w|W)ait ([0-9]+) sec(onds)?\.$/
      if $2.to_i > 1
        sleep($2.to_i - "0.2".to_f)
      else
        sleep 0.3
      end
      put_dir.call
    elsif line =~ /will have to stand up first|must be standing first|^You'll have to get up first|^But you're already sitting!|^Shouldn't you be standing first|^That would be quite a trick from that position\.  Try standing up\.|^Perhaps you should stand up|^Standing up might help|^You should really stand up first|You can't do that while sitting|You must be standing to do that|You can't do that while lying down/
      fput 'stand'
      waitrt?
      put_dir.call
    elsif line =~ /^You're still recovering from your recent/
      sleep 2
      put_dir.call
    elsif line =~ /^The ground approaches you at an alarming rate/
      sleep 1
      fput 'stand' unless standing?
      put_dir.call
    elsif line =~ /You go flying down several feet, landing with a/
      sleep 1
      fput 'stand' unless standing?
      put_dir.call
    elsif line =~ /^Sorry, you may only type ahead/
      sleep 1
      put_dir.call
    elsif line == 'You are still stunned.'
      wait_while { stunned? }
      put_dir.call
    elsif line =~ /you slip (?:on a patch of ice )?and flail uselessly as you land on your rear(?:\.|!)$|You wobble and stumble only for a moment before landing flat on your face!$|^You slip in the mud and fall flat on your back\!$/
      waitrt?
      fput 'stand' unless standing?
      waitrt?
      put_dir.call
    elsif line =~ /^You flick your hand (?:up|down)wards and focus your aura on your disk, but your disk only wobbles briefly\.$/
      put_dir.call
    elsif line =~ /^You dive into the fast-moving river, but the current catches you and whips you back to shore, wet and battered\.$|^Running through the swampy terrain, you notice a wet patch in the bog|^You flounder around in the water.$|^You blunder around in the water, barely able|^You struggle against the swift current to swim|^You slap at the water in a sad failure to swim|^You work against the swift current to swim/
      waitrt?
      put_dir.call
    elsif line =~ /^(You notice .* at your feet, and do not wish to leave it behind|As you prepare to move away, you remember)/
      fput "stow feet"
      sleep 1
      put_dir.call
    elsif line == "You don't seem to be able to move to do that."
      30.times {
        break if clear.include?('You regain control of your senses!')

        sleep 0.1
      }
      put_dir.call
    elsif line =~ /^It's pitch dark and you can't see a thing!/
      echo "You will need a light source to continue your journey"
      return true
    end
    if XMLData.room_count > room_count
      fill_hands if need_full_hands
      Script.current.downstream_buffer.unshift(save_stream)
      Script.current.downstream_buffer.flatten!
      return true
    end
    if Time.now.to_i >= giveup_time
      echo "move: no recognized response in #{giveup_seconds} seconds.  giving up."
      fill_hands if need_full_hands
      Script.current.downstream_buffer.unshift(save_stream)
      Script.current.downstream_buffer.flatten!
      return nil
    end
    if line_count >= giveup_lines
      echo "move: no recognized response after #{line_count} lines.  giving up."
      fill_hands if need_full_hands
      Script.current.downstream_buffer.unshift(save_stream)
      Script.current.downstream_buffer.flatten!
      return nil
    end
  }
end

# Watches the health of a character and executes a block or proc when health is no longer valid.
# 
# @param value [Integer] The health value to monitor.
# @param theproc [Proc, nil] An optional proc to execute if no block is given.
# @yield [Proc] A block to execute when health is no longer valid.
# @return [nil] Returns nil if no block or proc is provided.
# @raise [RuntimeError] If neither a block nor a proc is provided.
# @example
#   watchhealth(50) { puts "Health is low!" }
def watchhealth(value, theproc = nil, &block)
  value = value.to_i
  if block.nil?
    if !theproc.respond_to? :call
      respond "`watchhealth' was not given a block or a proc to execute!"
      return nil
    else
      block = theproc
    end
  end
  Thread.new {
    wait_while { health(value) }
    block.call
  }
end

# Waits until a condition is met, optionally announcing the status.
#
# @param announce [String, nil] An optional message to announce.
# @yield [Boolean] A block that returns true when the condition is met.
# @return [nil] Returns nil after the condition is met.
# @example
#   wait_until("Waiting for condition...") { condition_met? }
def wait_until(announce = nil)
  priosave = Thread.current.priority
  Thread.current.priority = 0
  unless announce.nil? or yield
    respond(announce)
  end
  until yield
    sleep 0.25
  end
  Thread.current.priority = priosave
end

# Waits while a condition is true, optionally announcing the status.
#
# @param announce [String, nil] An optional message to announce.
# @yield [Boolean] A block that returns true while the condition is true.
# @return [nil] Returns nil after the condition is no longer true.
# @example
#   wait_while("Waiting...") { condition_still_true? }
def wait_while(announce = nil)
  priosave = Thread.current.priority
  Thread.current.priority = 0
  unless announce.nil? or !yield
    respond(announce)
  end
  while yield
    sleep 0.25
  end
  Thread.current.priority = priosave
end

# Checks if a given direction is valid based on the room exits.
#
# @param dir [String] The direction to check.
# @return [Array, Boolean] Returns an array of valid directions or false if none exist.
# @example
#   checkpaths("north")
def checkpaths(dir = "none")
  if dir == "none"
    if XMLData.room_exits.empty?
      return false
    else
      return XMLData.room_exits.collect { |room_exits| SHORTDIR[room_exits] }
    end
  else
    XMLData.room_exits.include?(dir) || XMLData.room_exits.include?(SHORTDIR[dir])
  end
end

# Reverses a given direction.
#
# @param dir [String] The direction to reverse.
# @return [String, Boolean] Returns the reversed direction or false if unrecognized.
# @example
#   reverse_direction("n") # => "s"
def reverse_direction(dir)
  if dir == "n" then 's'
  elsif dir == "ne" then 'sw'
  elsif dir == "e" then 'w'
  elsif dir == "se" then 'nw'
  elsif dir == "s" then 'n'
  elsif dir == "sw" then 'ne'
  elsif dir == "w" then 'e'
  elsif dir == "nw" then 'se'
  elsif dir == "up" then 'down'
  elsif dir == "down" then 'up'
  elsif dir == "out" then 'out'
  elsif dir == 'o' then out
  elsif dir == 'u' then 'down'
  elsif dir == 'd' then up
  elsif dir == n then s
  elsif dir == ne then sw
  elsif dir == e then w
  elsif dir == se then nw
  elsif dir == s then n
  elsif dir == sw then ne
  elsif dir == w then e
  elsif dir == nw then se
  elsif dir == u then d
  elsif dir == d then u
  else
    echo("Cannot recognize direction to properly reverse it!"); false
  end
end

# Walks through boundaries until a condition is met.
#
# @param boundaries [Array] A list of boundaries to check.
# @yield [Boolean] A block that returns true when the walk should stop.
# @return [Object] Returns the value from the block when the condition is met.
# @example
#   walk("north", "south") { condition_met? }
def walk(*boundaries, &block)
  boundaries.flatten!
  unless block.nil?
    until (val = yield)
      walk(*boundaries)
    end
    return val
  end
  if $last_dir and !boundaries.empty? and checkroomdescrip =~ /#{boundaries.join('|')}/i
    move($last_dir)
    $last_dir = reverse_direction($last_dir)
    return checknpcs
  end
  dirs = checkpaths
  return checknpcs if dirs.is_a?(FalseClass)
  dirs.delete($last_dir) unless dirs.length < 2
  this_time = rand(dirs.length)
  $last_dir = reverse_direction(dirs[this_time])
  move(dirs[this_time])
  checknpcs
end

# Runs the walk method in a loop until it returns false.
#
# @return [nil] Returns nil when the loop is broken.
# @example
#   run
def run
  loop { break unless walk }
end

# Checks the mental state of the character.
#
# @param string [String, nil] An optional string to check against the mind state.
# @return [Boolean, String] Returns true if the mind state matches or the current mind text if no string is provided.
# @raise [RuntimeError] If the input is invalid.
# @example
#   check_mind("clear") # => true
def check_mind(string = nil)
  if string.nil?
    return XMLData.mind_text
  elsif (string.class == String) and (string.to_i == 0)
    if string =~ /#{XMLData.mind_text}/i
      return true
    else
      return false
    end
  elsif string.to_i.between?(0, 100)
    return string.to_i <= XMLData.mind_value.to_i
  else
    echo("check_mind error! You must provide an integer ranging from 0-100, the common abbreviation of how full your head is, or provide no input to have check_mind return an abbreviation of how filled your head is."); sleep 1
    return false
  end
end

# Checks the mental state of the character with a different approach.
#
# @param string [String, nil] An optional string to check against the mind state.
# @return [Boolean, nil] Returns true if the mind state matches or nil if the string is invalid.
# @raise [RuntimeError] If the input is invalid.
# @example
#   checkmind("clear") # => true
def checkmind(string = nil)
  if string.nil?
    return XMLData.mind_text
  elsif string.class == String and string.to_i == 0
    if string =~ /#{XMLData.mind_text}/i
      return true
    else
      return false
    end
  elsif string.to_i.between?(1, 8)
    mind_state = ['clear as a bell', 'fresh and clear', 'clear', 'muddled', 'becoming numbed', 'numbed', 'must rest', 'saturated']
    if mind_state.index(XMLData.mind_text)
      mind = mind_state.index(XMLData.mind_text) + 1
      return string.to_i <= mind
    else
      echo "Bad string in checkmind: mind_state"
      nil
    end
  else
    echo("Checkmind error! You must provide an integer ranging from 1-8 (7 is fried, 8 is 100% fried), the common abbreviation of how full your head is, or provide no input to have checkmind return an abbreviation of how filled your head is."); sleep 1
    return false
  end
end

# Checks the current mind value or compares it to a given number.
#
# @param num [Integer, nil] An optional number to compare against the current mind value.
# @return [Integer, Boolean] Returns the current mind value if no number is provided, or true if the current mind value is greater than or equal to the given number.
# @example
#   percentmind(50) # => true
def percentmind(num = nil)
  if num.nil?
    XMLData.mind_value
  else
    XMLData.mind_value >= num.to_i
  end
end

# Checks if the character's mind state indicates they must rest.
#
# @return [Boolean] Returns true if the mind state indicates rest is needed.
# @example
#   checkfried # => true or false
def checkfried
  if XMLData.mind_text =~ /must rest|saturated/
    true
  else
    false
  end
end

# Checks if the character's mind state is saturated.
#
# @return [Boolean] Returns true if the mind state is saturated.
# @example
#   checksaturated # => true or false
def checksaturated
  if XMLData.mind_text =~ /saturated/
    true
  else
    false
  end
end

# Checks the current mana value or compares it to a given number.
#
# @param num [Integer, nil] An optional number to compare against the current mana value.
# @return [Integer, Boolean] Returns the current mana value if no number is provided, or true if the current mana value is greater than or equal to the given number.
# @example
#   checkmana(30) # => true
def checkmana(num = nil)
  Lich.deprecated('checkmana', 'Char.mana')
  if num.nil?
    XMLData.mana
  else
    XMLData.mana >= num.to_i
  end
end

# Returns the maximum mana value.
#
# @return [Integer] The maximum mana value.
# @example
#   maxmana # => 100
def maxmana
  Lich.deprecated('maxmana', 'Char.maxmana')
  XMLData.max_mana
end

# Checks the percentage of current mana relative to maximum mana.
#
# @param num [Integer, nil] An optional number to compare against the current mana percentage.
# @return [Integer, Boolean] Returns the current mana percentage if no number is provided, or true if the current mana percentage is greater than or equal to the given number.
# @example
#   percentmana(50) # => true
def percentmana(num = nil)
  Lich.deprecated('percentmana', 'Char.percent_mana')
  if XMLData.max_mana == 0
    percent = 100
  else
    percent = ((XMLData.mana.to_f / XMLData.max_mana.to_f) * 100).to_i
  end
  if num.nil?
    percent
  else
    percent >= num.to_i
  end
end

# Checks the current health value or compares it to a given number.
#
# @param num [Integer, nil] An optional number to compare against the current health value.
# @return [Integer, Boolean] Returns the current health value if no number is provided, or true if the current health value is greater than or equal to the given number.
# @example
#   checkhealth(50) # => true
def checkhealth(num = nil)
  Lich.deprecated('checkhealth', 'Char.health')
  if num.nil?
    XMLData.health
  else
    XMLData.health >= num.to_i
  end
end

# Returns the maximum health value.
#
# @return [Integer] The maximum health value.
# @example
#   maxhealth # => 100
def maxhealth
  Lich.deprecated('maxhealth', 'Char.max_health')
  XMLData.max_health
end

# Checks the percentage of current health relative to maximum health.
#
# @param num [Integer, nil] An optional number to compare against the current health percentage.
# @return [Integer, Boolean] Returns the current health percentage if no number is provided, or true if the current health percentage is greater than or equal to the given number.
# @example
#   percenthealth(50) # => true
def percenthealth(num = nil)
  Lich.deprecated('percenthealth', 'Char.percent_health')
  if num.nil?
    ((XMLData.health.to_f / XMLData.max_health.to_f) * 100).to_i
  else
    ((XMLData.health.to_f / XMLData.max_health.to_f) * 100).to_i >= num.to_i
  end
end

# Checks the current spirit value or compares it to a given number.
#
# @param num [Integer, nil] An optional number to compare against the current spirit value.
# @return [Integer, Boolean] Returns the current spirit value if no number is provided, or true if the current spirit value is greater than or equal to the given number.
# @example
#   checkspirit(30) # => true
def checkspirit(num = nil)
  Lich.deprecated('checkspirit', 'Char.spirit')
  if num.nil?
    XMLData.spirit
  else
    XMLData.spirit >= num.to_i
  end
end

# Returns the maximum spirit value.
#
# @return [Integer] The maximum spirit value.
# @example
#   maxspirit # => 100
def maxspirit
  Lich.deprecated('maxspirit', 'Char.max_spirit')
  XMLData.max_spirit
end

# Calculates the percentage of spirit based on current and maximum spirit values.
# 
# @param num [Integer, nil] Optional threshold to compare against the calculated percentage.
# @return [Integer, Boolean] If num is nil, returns the percentage of spirit as an Integer. 
# If num is provided, returns true if the percentage is greater than or equal to num, otherwise false.
# @raise [NoMethodError] If XMLData does not respond to spirit or max_spirit.
# @example
#   percentspirit # => 75
#   percentspirit(80) # => false
def percentspirit(num = nil)
  Lich.deprecated('percentspirit', 'Char.percent_spirit')
  if num.nil?
    ((XMLData.spirit.to_f / XMLData.max_spirit.to_f) * 100).to_i
  else
    ((XMLData.spirit.to_f / XMLData.max_spirit.to_f) * 100).to_i >= num.to_i
  end
end

# Checks the current stamina or compares it against a given threshold.
# 
# @param num [Integer, nil] Optional threshold to compare against the current stamina.
# @return [Integer, Boolean] If num is nil, returns the current stamina as an Integer. 
# If num is provided, returns true if current stamina is greater than or equal to num, otherwise false.
# @raise [NoMethodError] If XMLData does not respond to stamina.
# @example
#   checkstamina # => 50
#   checkstamina(40) # => true
def checkstamina(num = nil)
  Lich.deprecated('checkstamina', 'Char.stamina')
  if num.nil?
    XMLData.stamina
  else
    XMLData.stamina >= num.to_i
  end
end

# Retrieves the maximum stamina value.
# 
# @return [Integer] The maximum stamina value.
# @raise [NoMethodError] If XMLData does not respond to max_stamina.
# @example
#   maxstamina # => 100
def maxstamina()
  Lich.deprecated('maxstamina', 'Char.max_stamina')
  XMLData.max_stamina
end

# Calculates the percentage of stamina based on current and maximum stamina values.
# 
# @param num [Integer, nil] Optional threshold to compare against the calculated percentage.
# @return [Integer, Boolean] If num is nil, returns the percentage of stamina as an Integer. 
# If num is provided, returns true if the percentage is greater than or equal to num, otherwise false.
# @raise [NoMethodError] If XMLData does not respond to stamina or max_stamina.
# @example
#   percentstamina # => 75
#   percentstamina(80) # => false
def percentstamina(num = nil)
  Lich.deprecated('percentstamina', 'Char.percent_stamina')
  if XMLData.max_stamina == 0
    percent = 100
  else
    percent = ((XMLData.stamina.to_f / XMLData.max_stamina.to_f) * 100).to_i
  end
  if num.nil?
    percent
  else
    percent >= num.to_i
  end
end

# Retrieves the maximum concentration value.
# 
# @return [Integer] The maximum concentration value.
# @raise [NoMethodError] If XMLData does not respond to max_concentration.
# @example
#   maxconcentration # => 100
def maxconcentration()
  XMLData.max_concentration
end

# Calculates the percentage of concentration based on current and maximum concentration values.
# 
# @param num [Integer, nil] Optional threshold to compare against the calculated percentage.
# @return [Integer, Boolean] If num is nil, returns the percentage of concentration as an Integer. 
# If num is provided, returns true if the percentage is greater than or equal to num, otherwise false.
# @raise [NoMethodError] If XMLData does not respond to concentration or max_concentration.
# @example
#   percentconcentration # => 50
#   percentconcentration(60) # => false
def percentconcentration(num = nil)
  if XMLData.max_concentration == 0
    percent = 100
  else
    percent = ((XMLData.concentration.to_f / XMLData.max_concentration.to_f) * 100).to_i
  end
  if num.nil?
    percent
  else
    percent >= num.to_i
  end
end

# Checks the current stance or compares it against a given threshold.
# 
# @param num [String, Integer, nil] Optional stance description or value to compare against.
# @return [String, Boolean, nil] If num is nil, returns the current stance text. 
# If num is a valid stance description or value, returns true if the current stance matches, otherwise false.
# @raise [ArgumentError] If num is not a valid type.
# @example
#   checkstance # => "offensive"
#   checkstance("defensive") # => true
def checkstance(num = nil)
  Lich.deprecated('checkstance', 'Char.stance')
  if num.nil?
    XMLData.stance_text
  elsif (num.class == String) and (num.to_i == 0)
    if num =~ /off/i
      XMLData.stance_value == 0
    elsif num =~ /adv/i
      XMLData.stance_value.between?(01, 20)
    elsif num =~ /for/i
      XMLData.stance_value.between?(21, 40)
    elsif num =~ /neu/i
      XMLData.stance_value.between?(41, 60)
    elsif num =~ /gua/i
      XMLData.stance_value.between?(61, 80)
    elsif num =~ /def/i
      XMLData.stance_value == 100
    else
      echo "checkstance: invalid argument (#{num}).  Must be off/adv/for/neu/gua/def or 0-100"
      nil
    end
  elsif (num.class == Integer) or (num =~ /^[0-9]+$/ and (num = num.to_i))
    XMLData.stance_value == num.to_i
  else
    echo "checkstance: invalid argument (#{num}).  Must be off/adv/for/neu/gua/def or 0-100"
    nil
  end
end

# Retrieves the current stance value or compares it against a given threshold.
# 
# @param num [Integer, nil] Optional threshold to compare against the current stance value.
# @return [Integer, Boolean] If num is nil, returns the current stance value as an Integer. 
# If num is provided, returns true if the current stance value is greater than or equal to num, otherwise false.
# @raise [NoMethodError] If XMLData does not respond to stance_value.
# @example
#   percentstance # => 50
#   percentstance(60) # => false
def percentstance(num = nil)
  Lich.deprecated('percentstance', 'Char.percent_stance')
  if num.nil?
    XMLData.stance_value
  else
    XMLData.stance_value >= num.to_i
  end
end

# Checks the current encumbrance or compares it against a given string or value.
# 
# @param string [String, Integer, nil] Optional encumbrance description or value to compare against.
# @return [String, Boolean, nil] If string is nil, returns the current encumbrance text. 
# If string is a valid description or value, returns true if the current encumbrance matches, otherwise false.
# @raise [ArgumentError] If string is not a valid type.
# @example
#   checkencumbrance # => "Lightly Encumbered"
#   checkencumbrance("Heavy") # => false
def checkencumbrance(string = nil)
  Lich.deprecated('checkencumbrance', 'Char.encumbrance')
  if string.nil?
    XMLData.encumbrance_text
  elsif (string.class == Integer) or (string =~ /^[0-9]+$/ and (string = string.to_i))
    string <= XMLData.encumbrance_value
  else
    # fixme
    if string =~ /#{XMLData.encumbrance_text}/i
      true
    else
      false
    end
  end
end

# Calculates the percentage of encumbrance based on current encumbrance value.
# 
# @param num [Integer, nil] Optional threshold to compare against the current encumbrance value.
# @return [Integer, Boolean] If num is nil, returns the current encumbrance value as an Integer. 
# If num is provided, returns true if the current encumbrance value is greater than or equal to num, otherwise false.
# @raise [NoMethodError] If XMLData does not respond to encumbrance_value.
# @example
#   percentencumbrance # => 30
#   percentencumbrance(40) # => false
def percentencumbrance(num = nil)
  Lich.deprecated('percentencumbrance', 'Char.percent_encumbrance')
  if num.nil?
    XMLData.encumbrance_value
  else
    num.to_i <= XMLData.encumbrance_value
  end
end

# Checks if the current area matches any of the provided strings.
# 
# @param strings [Array<String>] Optional list of area descriptions to check against.
# @return [String, Boolean] If strings are empty, returns the current room title. 
# If strings are provided, returns true if the room title matches any of the strings, otherwise false.
# @example
#   checkarea # => "Town Square"
#   checkarea("Town", "Village") # => true
def checkarea(*strings)
  strings.flatten!
  if strings.empty?
    XMLData.room_title.split(',').first.sub('[', '')
  else
    XMLData.room_title.split(',').first =~ /#{strings.join('|')}/i
  end
end

# Checks if the current room matches any of the provided strings.
# 
# @param strings [Array<String>] Optional list of room descriptions to check against.
# @return [String, Boolean] If strings are empty, returns the current room title. 
# If strings are provided, returns true if the room title matches any of the strings, otherwise false.
# @example
#   checkroom # => "Town Square"
#   checkroom("Town", "Village") # => true
def checkroom(*strings)
  strings.flatten!
  if strings.empty?
    XMLData.room_title.chomp
  else
    XMLData.room_title =~ /#{strings.join('|')}/i
  end
end

# Checks if the player is currently outside based on room exits.
# 
# @return [Boolean] Returns true if the room has obvious paths, otherwise false.
# @example
#   outside? # => true
def outside?
  if XMLData.room_exits_string =~ /Obvious paths:/
    true
  else
    false
  end
end

# Checks the current familiar area or compares it against a given string.
# 
# @param strings [Array<String>] Optional list of familiar area descriptions to check against.
# @return [String, Boolean] If strings are empty, returns the current familiar room title. 
# If strings are provided, returns true if the familiar room title matches any of the strings, otherwise false.
# @example
#   checkfamarea # => "Familiar Area"
#   checkfamarea("Familiar", "Area") # => true
def checkfamarea(*strings)
  strings.flatten!
  if strings.empty? then return XMLData.familiar_room_title.split(',').first.sub('[', '') end

  XMLData.familiar_room_title.split(',').first =~ /#{strings.join('|')}/i
end

# Checks the available paths for the familiar in the specified direction.
# 
# @param dir [String] The direction to check for familiar paths. Defaults to "none".
# @return [Boolean, Array<String>] If dir is "none", returns false if there are no exits, 
# otherwise returns the list of exits. If dir is specified, returns true if the direction is included in exits, otherwise false.
# @example
#   checkfampaths # => ["north", "south"]
#   checkfampaths("north") # => true
def checkfampaths(dir = "none")
  if dir == "none"
    if XMLData.familiar_room_exits.empty?
      return false
    else
      return XMLData.familiar_room_exits
    end
  else
    XMLData.familiar_room_exits.include?(dir)
  end
end

# Checks the current familiar room or compares it against a given string.
# 
# @param strings [Array<String>] Optional list of familiar room descriptions to check against.
# @return [String, Boolean] If strings are empty, returns the current familiar room title. 
# If strings are provided, returns true if the familiar room title matches any of the strings, otherwise false.
# @example
#   checkfamroom # => "Familiar Room"
#   checkfamroom("Familiar", "Room") # => true
def checkfamroom(*strings)
  strings.flatten!; if strings.empty? then return XMLData.familiar_room_title.chomp end

  XMLData.familiar_room_title =~ /#{strings.join('|')}/i
end

# Checks the current familiar NPCs or compares them against a given list of strings.
# 
# @param strings [Array<String>] Optional list of NPC descriptions to check against.
# @return [Array<String>, Boolean] If strings are empty, returns an array of familiar NPC names. 
# If strings are provided, returns true if any of the NPC names match, otherwise false.
# @example
#   checkfamnpcs # => ["Goblin", "Orc"]
#   checkfamnpcs("Goblin") # => true
def checkfamnpcs(*strings)
  parsed = Array.new
  XMLData.familiar_npcs.each { |val| parsed.push(val.split.last) }
  if strings.empty?
    if parsed.empty?
      return false
    else
      return parsed
    end
  else
    if (mtch = strings.find { |lookfor| parsed.find { |critter| critter =~ /#{lookfor}/ } })
      return mtch
    else
      return false
    end
  end
end

# Checks the current familiar PCs or compares them against a given list of strings.
# 
# @param strings [Array<String>] Optional list of PC descriptions to check against.
# @return [Array<String>, Boolean] If strings are empty, returns an array of familiar PC names. 
# If strings are provided, returns true if any of the PC names match, otherwise false.
# @example
#   checkfampcs # => ["Hero", "Mage"]
#   checkfampcs("Hero") # => true
def checkfampcs(*strings)
  familiar_pcs = Array.new
  XMLData.familiar_pcs.to_s.gsub(/Lord |Lady |Great |High |Renowned |Grand |Apprentice |Novice |Journeyman /, '').split(',').each { |line| familiar_pcs.push(line.slice(/[A-Z][a-z]+/)) }
  if familiar_pcs.empty?
    return false
  elsif strings.empty?
    return familiar_pcs
  else
    regexpstr = strings.join('|\b')
    peeps = familiar_pcs.find_all { |val| val =~ /\b#{regexpstr}/i }
    if peeps.empty?
      return false
    else
      return peeps
    end
  end
end

# Checks the current PCs or compares them against a given list of strings.
# 
# @param strings [Array<String>] Optional list of PC descriptions to check against.
# @return [Array<String>, Boolean] If strings are empty, returns an array of PC names. 
# If strings are provided, returns true if any of the PC names match, otherwise false.
# @example
#   checkpcs # => ["Warrior", "Mage"]
#   checkpcs("Warrior") # => true
def checkpcs(*strings)
  pcs = GameObj.pcs.collect { |pc| pc.noun }
  if pcs.empty?
    if strings.empty? then return nil else return false end
  end
  strings.flatten!
  if strings.empty?
    pcs
  else
    regexpstr = strings.join(' ')
    pcs.find { |pc| regexpstr =~ /\b#{pc}/i }
  end
end

# Checks the current NPCs or compares them against a given list of strings.
# 
# @param strings [Array<String>] Optional list of NPC descriptions to check against.
# @return [Array<String>, Boolean] If strings are empty, returns an array of NPC names. 
# If strings are provided, returns true if any of the NPC names match, otherwise false.
# @example
#   checknpcs # => ["Goblin", "Orc"]
#   checknpcs("Goblin") # => true
def checknpcs(*strings)
  npcs = GameObj.npcs.collect { |npc| npc.noun }
  if npcs.empty?
    if strings.empty? then return nil else return false end
  end
  strings.flatten!
  if strings.empty?
    npcs
  else
    regexpstr = strings.join(' ')
    npcs.find { |npc| regexpstr =~ /\b#{npc}/i }
  end
end

# Counts the number of current NPCs.
# 
# @return [Integer] The count of NPCs.
# @example
#   count_npcs # => 5
def count_npcs
  checknpcs.length
end

# Checks the right hand for a matching instance from the provided hand.
# 
# @param hand [Array] A list of instances to check against the right hand.
# @return [String, nil] The noun of the right hand if no instances match, or nil if the right hand is empty or not set.
# @example
#   checkright("sword", "shield")
def checkright(*hand)
  if GameObj.right_hand.nil? then return nil end

  hand.flatten!
  if GameObj.right_hand.name == "Empty" or GameObj.right_hand.name.empty?
    nil
  elsif hand.empty?
    GameObj.right_hand.noun
  else
    hand.find { |instance| GameObj.right_hand.name =~ /#{instance}/i }
  end
end

# Checks the left hand for a matching instance from the provided hand.
# 
# @param hand [Array] A list of instances to check against the left hand.
# @return [String, nil] The noun of the left hand if no instances match, or nil if the left hand is empty or not set.
# @example
#   checkleft("dagger", "axe")
def checkleft(*hand)
  if GameObj.left_hand.nil? then return nil end

  hand.flatten!
  if GameObj.left_hand.name == "Empty" or GameObj.left_hand.name.empty?
    nil
  elsif hand.empty?
    GameObj.left_hand.noun
  else
    hand.find { |instance| GameObj.left_hand.name =~ /#{instance}/i }
  end
end

# Checks the room description for a match with the provided values.
# 
# @param val [Array] A list of values to check against the room description.
# @return [Integer, nil] The index of the first match or nil if no matches are found.
# @example
#   checkroomdescrip("dark", "mysterious")
def checkroomdescrip(*val)
  val.flatten!
  if val.empty?
    return XMLData.room_description
  else
    return XMLData.room_description =~ /#{val.join('|')}/i
  end
end

# Checks the familiar room description for a match with the provided values.
# 
# @param val [Array] A list of values to check against the familiar room description.
# @return [Integer, nil] The index of the first match or nil if no matches are found.
# @example
#   checkfamroomdescrip("cozy", "warm")
def checkfamroomdescrip(*val)
  val.flatten!
  if val.empty?
    return XMLData.familiar_room_description
  else
    return XMLData.familiar_room_description =~ /#{val.join('|')}/i
  end
end

# Checks if all provided spells are currently active.
# 
# @param spells [Array] A list of spell names to check for activity.
# @return [Boolean] True if all spells are active, false otherwise.
# @example
#   checkspell("fireball", "lightning")
def checkspell(*spells)
  spells.flatten!
  return false if Spell.active.empty?

  spells.each { |spell| return false unless Spell[spell].active? }
  true
end

# Checks the prepared spell status.
# 
# @param spell [String, nil] The name of the spell to check or nil to return the current prepared spell.
# @return [Boolean, String] True if the spell is prepared, the name of the prepared spell if no argument is given, or false on error.
# @raise [RuntimeError] If the spell is not a string when provided.
# @example
#   checkprep("fireball")
def checkprep(spell = nil)
  if spell.nil?
    XMLData.prepared_spell
  elsif spell.class != String
    echo("Checkprep error, spell # not implemented!  You must use the spell name")
    false
  else
    XMLData.prepared_spell =~ /^#{spell}/i
  end
end

# Sets the priority of the current thread.
# 
# @param val [Integer, nil] The new priority value or nil to return the current priority.
# @return [Integer] The current priority of the thread.
# @raise [RuntimeError] If the priority value is greater than 3.
# @example
#   setpriority(2)
def setpriority(val = nil)
  if val.nil? then return Thread.current.priority end

  if val.to_i > 3
    echo("You're trying to set a script's priority as being higher than the send/recv threads (this is telling Lich to run the script before it even gets data to give the script, and is useless); the limit is 3")
    return Thread.current.priority
  else
    Thread.current.group.list.each { |thr| thr.priority = val.to_i }
    return Thread.current.priority
  end
end

# Checks if there is a current bounty task.
# 
# @return [Object, nil] The current bounty task if it exists, or nil if not.
# @example
#   checkbounty
def checkbounty
  if XMLData.bounty_task
    return XMLData.bounty_task
  else
    return nil
  end
end

# Checks if the player is currently sleeping.
# 
# @return [Boolean] True if the player is sleeping, false otherwise.
# @raise [RuntimeError] If the game does not support the sleeping check.
# @example
#   checksleeping
def checksleeping
  return Status.sleeping? if XMLData.game =~ /GS/
  fail "Error: toplevel checksleeping command not enabled in #{XMLData.game}"
end

# Checks if the player is currently sleeping.
# 
# @return [Boolean] True if the player is sleeping, false otherwise.
# @raise [RuntimeError] If the game does not support the sleeping check.
# @example
#   sleeping?
def sleeping?
  return Status.sleeping? if XMLData.game =~ /GS/
  fail "Error: toplevel sleeping? command not enabled in #{XMLData.game}"
end

# Checks if the player is currently bound.
# 
# @return [Boolean] True if the player is bound, false otherwise.
# @raise [RuntimeError] If the game does not support the bound check.
# @example
#   checkbound
def checkbound
  return Status.bound? if XMLData.game =~ /GS/
  fail "Error: toplevel checkbound command not enabled in #{XMLData.game}"
end

# Checks if the player is currently bound.
# 
# @return [Boolean] True if the player is bound, false otherwise.
# @raise [RuntimeError] If the game does not support the bound check.
# @example
#   bound?
def bound?
  return Status.bound? if XMLData.game =~ /GS/
  fail "Error: toplevel bound? command not enabled in #{XMLData.game}"
end

# Checks if the player is currently silenced.
# 
# @return [Boolean] True if the player is silenced, false otherwise.
# @raise [RuntimeError] If the game does not support the silenced check.
# @example
#   checksilenced
def checksilenced
  return Status.silenced? if XMLData.game =~ /GS/
  fail "Error: toplevel checksilenced command not enabled in #{XMLData.game}"
end

# Checks if the player is currently silenced.
# 
# @return [Boolean] True if the player is silenced, false otherwise.
# @raise [RuntimeError] If the game does not support the silenced check.
# @example
#   silenced?
def silenced?
  return Status.silenced? if XMLData.game =~ /GS/
  fail "Error: toplevel silenced? command not enabled in #{XMLData.game}"
end

# Checks if the player is currently calmed.
# 
# @return [Boolean] True if the player is calmed, false otherwise.
# @raise [RuntimeError] If the game does not support the calmed check.
# @example
#   checkcalmed
def checkcalmed
  return Status.calmed? if XMLData.game =~ /GS/
  fail "Error: toplevel checkcalmed command not enabled in #{XMLData.game}"
end

# Checks if the player is currently calmed.
# 
# @return [Boolean] True if the player is calmed, false otherwise.
# @raise [RuntimeError] If the game does not support the calmed check.
# @example
#   calmed?
def calmed?
  return Status.calmed? if XMLData.game =~ /GS/
  fail "Error: toplevel calmed? command not enabled in #{XMLData.game}"
end

# Checks if the player is currently cutthroat.
# 
# @return [Boolean] True if the player is cutthroat, false otherwise.
# @raise [RuntimeError] If the game does not support the cutthroat check.
# @example
#   checkcutthroat
def checkcutthroat
  return Status.cutthroat? if XMLData.game =~ /GS/
  fail "Error: toplevel checkcutthroat command not enabled in #{XMLData.game}"
end

# Checks if the player is currently cutthroat.
# 
# @return [Boolean] True if the player is cutthroat, false otherwise.
# @raise [RuntimeError] If the game does not support the cutthroat check.
# @example
#   cutthroat?
def cutthroat?
  return Status.cutthroat? if XMLData.game =~ /GS/
  fail "Error: toplevel cutthroat? command not enabled in #{XMLData.game}"
end

# Retrieves the variables of the current script.
# 
# @return [Hash, nil] A hash of variables for the current script or nil if the script cannot be identified.
# @example
#   variable
def variable
  unless (script = Script.current) then echo 'variable: cannot identify calling script.'; return nil; end
  script.vars
end

# Pauses execution for a specified duration.
# 
# @param num [String, Numeric] The duration to pause, can include units (m, h, d).
# @return [nil] Returns nil after the pause.
# @example
#   pause(5) # pauses for 5 seconds
def pause(num = 1)
  if num.to_s =~ /m/
    sleep((num.sub(/m/, '').to_f * 60))
  elsif num.to_s =~ /h/
    sleep((num.sub(/h/, '').to_f * 3600))
  elsif num.to_s =~ /d/
    sleep((num.sub(/d/, '').to_f * 86400))
  else
    sleep(num.to_f)
  end
end

# Casts a spell on a target.
# 
# @param spell [Spell, String, Integer] The spell to cast, can be a Spell object, spell name, or spell ID.
# @param target [Object, nil] The target of the spell, or nil if no target is specified.
# @param results_of_interest [Object, nil] Additional results of interest, or nil if not specified.
# @return [Boolean] True if the spell was successfully cast, false otherwise.
# @example
#   cast("fireball", target)
def cast(spell, target = nil, results_of_interest = nil)
  if spell.class == Spell
    spell.cast(target, results_of_interest)
  elsif ((spell.class == Integer) or (spell.to_s =~ /^[0-9]+$/)) and (find_spell = Spell[spell.to_i])
    find_spell.cast(target, results_of_interest)
  elsif (spell.class == String) and (find_spell = Spell[spell])
    find_spell.cast(target, results_of_interest)
  else
    echo "cast: invalid spell (#{spell})"
    false
  end
end

# Clears the downstream buffer of the current script.
# 
# @param _opt [Integer] An optional parameter, defaults to 0.
# @return [Array] The contents of the buffer before clearing it.
# @example
#   clear
def clear(_opt = 0)
  unless (script = Script.current) then respond('--- clear: Unable to identify calling script.'); return false; end
  to_return = script.downstream_buffer.dup
  script.downstream_buffer.clear
  to_return
end

# Matches a label and string against the game line queue.
# 
# @param label [String] The label to match.
# @param string [String] The string to match.
# @return [String, false] The matched string or false if no match is found.
# @raise [RuntimeError] If the script cannot be identified.
# @example
#   match("label", "string")
def match(label, string)
  strings = [label, string]
  strings.flatten!
  unless (script = Script.current) then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting..."); Thread.current.kill; return false end
  if strings.empty? then echo("Error! 'match' was given no strings to look for!"); sleep 1; return false end
  unless strings.length == 2
    while (line_in = script.gets)
      strings.each { |string|
        if line_in =~ /#{string}/ then return $~.to_s end
      }
    end
  else
    if script.respond_to?(:match_stack_add)
      script.match_stack_add(strings.first.to_s, strings.last)
    else
      script.match_stack_labels.push(strings[0].to_s)
      script.match_stack_strings.push(strings[1])
    end
  end
end

# Waits for a match within a specified timeout period.
# 
# @param secs [Integer, Float] The number of seconds to wait for a match.
# @param strings [Array] A list of strings to match against.
# @return [String, false] The matched line or false if the timeout expires.
# @raise [RuntimeError] If the script cannot be identified or if secs is not a number.
# @example
#   matchtimeout(30, "You stand up")
def matchtimeout(secs, *strings)
  unless (Script.current) then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting..."); Thread.current.kill; return false end
  unless (secs.class == Float || secs.class == Integer)
    echo('matchtimeout error! You appear to have given it a string, not a #! Syntax:  matchtimeout(30, "You stand up")')
    return false
  end
  strings.flatten!
  if strings.empty?
    echo("matchtimeout without any strings to wait for!")
    sleep 1
    return false
  end
  regexpstr = strings.join('|')
  end_time = Time.now.to_f + secs
  loop {
    line = get?
    if line.nil?
      sleep 0.1
    elsif line =~ /#{regexpstr}/i
      return line
    end
    if (Time.now.to_f > end_time)
      return false
    end
  }
end

# Matches a string before a specified condition.
# 
# @param strings [Array] A list of strings to match against.
# @return [String, false] The matched string or false if no match is found.
# @raise [RuntimeError] If the script cannot be identified.
# @example
#   matchbefore("string1", "string2")
def matchbefore(*strings)
  strings.flatten!
  unless (script = Script.current) then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting..."); Thread.current.kill; return false end
  if strings.empty? then echo("matchbefore without any strings to wait for!"); return false end
  regexpstr = strings.join('|')
  loop { if (script.gets) =~ /#{regexpstr}/ then return $`.to_s end }
end

# Matches a string after a specified condition.
# 
# @param strings [Array] A list of strings to match against.
# @return [String, false] The matched string or false if no match is found.
# @raise [RuntimeError] If the script cannot be identified.
# @example
#   matchafter("string1", "string2")
def matchafter(*strings)
  strings.flatten!
  unless (script = Script.current) then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting..."); Thread.current.kill; return false end
  if strings.empty? then echo("matchafter without any strings to wait for!"); return end
  regexpstr = strings.join('|')
  loop { if (script.gets) =~ /#{regexpstr}/ then return $'.to_s end }
end

# Matches any of the provided strings in the input until a match is found.
# 
# @param strings [Array<String>] The strings to match against the input.
# @return [Array<String>] An array containing the matched string before and after the match.
# @raise [RuntimeError] If the current script context is unknown.
# @example
#   matchboth("hello", "world")
def matchboth(*strings)
  strings.flatten!
  unless (script = Script.current) then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting..."); Thread.current.kill; return false end
  if strings.empty? then echo("matchboth without any strings to wait for!"); return end
  regexpstr = strings.join('|')
  loop { if (script.gets) =~ /#{regexpstr}/ then break end }
  return [$`.to_s, $'.to_s]
end

# Waits for a line of input that matches any of the provided strings.
#
# @param strings [Array<String, Regexp>] The strings or regular expressions to match against the input.
# @return [String, nil] The matched line of input or nil if no match is found.
# @raise [RuntimeError] If the current script context is unknown.
# @example
#   matchwait("start", /end/)
def matchwait(*strings)
  unless (script = Script.current) then respond('--- matchwait: Unable to identify calling script.'); return false; end
  strings.flatten!
  unless strings.empty?
    regexpstr = strings.collect { |str| str.kind_of?(Regexp) ? str.source : str }.join('|')
    regexobj = /#{regexpstr}/
    while (line_in = script.gets)
      return line_in if line_in =~ regexobj
    end
  else
    strings = script.match_stack_strings
    labels = script.match_stack_labels
    regexpstr = /#{strings.join('|')}/i
    while (line_in = script.gets)
      if (mdata = regexpstr.match(line_in))
        jmp = labels[strings.index(mdata.to_s) || strings.index(strings.find { |str| line_in =~ /#{str}/i })]
        script.match_stack_clear
        goto jmp
      end
    end
  end
end

# Waits for a line of input that matches the provided regular expression.
#
# @param regexp [Regexp] The regular expression to match against the input.
# @return [nil] Returns nil if the input does not match the regular expression.
# @raise [RuntimeError] If the current script context is unknown or if the provided argument is not a Regexp.
# @example
#   waitforre(/error/)
def waitforre(regexp)
  unless (script = Script.current) then respond('--- waitforre: Unable to identify calling script.'); return false; end
  unless regexp.class == Regexp then echo("Script error! You have given 'waitforre' something to wait for, but it isn't a Regular Expression! Use 'waitfor' if you want to wait for a string."); sleep 1; return nil end
  regobj = regexp.match(script.gets) until regobj
end

# Waits for a line of input that matches any of the provided strings.
#
# @param strings [Array<String>] The strings to match against the input.
# @return [String, false] The matched line of input or false if no match is found.
# @raise [RuntimeError] If the current script context is unknown.
# @example
#   waitfor("hello", "world")
def waitfor(*strings)
  unless (script = Script.current) then respond('--- waitfor: Unable to identify calling script.'); return false; end
  strings.flatten!
  if (script.class == WizardScript) and (strings.length == 1) and (strings.first.strip == '>')
    return script.gets
  end

  if strings.empty?
    echo 'waitfor: no string to wait for'
    return false
  end
  regexpstr = strings.join('|')
  while true
    line_in = script.gets
    if (line_in =~ /#{regexpstr}/i) then return line_in end
  end
end

# Waits for a line of input and clears the script's buffer.
#
# @return [String] The line of input received.
# @raise [RuntimeError] If the current script context is unknown.
# @example
#   wait
def wait
  unless (script = Script.current) then respond('--- wait: unable to identify calling script.'); return false; end
  script.clear
  return script.gets
end

# Retrieves a line of input from the current script.
#
# @return [String] The line of input received.
# @example
#   get
def get
  Script.current.gets
end

# Checks if there is a line of input available from the current script.
#
# @return [Boolean] True if there is input available, false otherwise.
# @example
#   get?
def get?
  Script.current.gets?
end

# Retrieves lines of input based on the provided criteria.
#
# @param lines [Array<String, Numeric>] The lines to match against the input.
# @return [Array<String>, nil] An array of matched lines or nil if no matches are found.
# @raise [RuntimeError] If the current script context is unknown.
# @example
#   reget("error", "warning")
def reget(*lines)
  unless (script = Script.current) then respond('--- reget: Unable to identify calling script.'); return false; end
  lines.flatten!
  if caller.find { |c| c =~ /regetall/ }
    history = ($_SERVERBUFFER_.history + $_SERVERBUFFER_).join("\n")
  else
    history = $_SERVERBUFFER_.dup.join("\n")
  end
  unless script.want_downstream_xml
    history.gsub!(/<pushStream id=["'](?:spellfront|inv|bounty|society)["'][^>]*\/>.*?<popStream[^>]*>/m, '')
    history.gsub!(/<stream id="Spells">.*?<\/stream>/m, '')
    history.gsub!(/<(compDef|inv|component|right|left|spell|prompt)[^>]*>.*?<\/\1>/m, '')
    history.gsub!(/<[^>]+>/, '')
    history.gsub!('&gt;', '>')
    history.gsub!('&lt;', '<')
  end
  history = history.split("\n").delete_if { |line| line.nil? or line.empty? or line =~ /^[\r\n\s\t]*$/ }
  if lines.first.kind_of?(Numeric) or lines.first.to_i.nonzero?
    history = history[-([lines.shift.to_i, history.length].min)..-1]
  end
  unless lines.empty? or lines.nil?
    regex = /#{lines.join('|')}/i
    history = history.find_all { |line| line =~ regex }
  end
  if history.empty?
    nil
  else
    history
  end
end

# Retrieves all lines of input based on the provided criteria.
#
# @param lines [Array<String, Numeric>] The lines to match against the input.
# @return [Array<String>, nil] An array of matched lines or nil if no matches are found.
# @example
#   regetall("error", "warning")
def regetall(*lines)
  reget(*lines)
end

# Sends multiple commands to the script.
#
# @param cmds [Array<String>] The commands to send.
# @return [void]
# @example
#   multifput("command1", "command2")
def multifput(*cmds)
  cmds.flatten.compact.each { |cmd| fput(cmd) }
end

# Sends a message to the script and waits for a response.
#
# @param message [String] The message to send.
# @param waitingfor [Array<String>] The strings to wait for in response.
# @return [String, false] The response string or false if no valid response is received.
# @raise [RuntimeError] If the current script context is unknown.
# @example
#   fput("hello", "world")
def fput(message, *waitingfor)
  unless (script = Script.current) then respond('--- waitfor: Unable to identify calling script.'); return false; end
  waitingfor.flatten!
  clear
  put(message)

  while (string = get)
    if string =~ /(?:\.\.\.wait |Wait )[0-9]+/
      hold_up = string.slice(/[0-9]+/).to_i
      sleep(hold_up) unless hold_up.nil?
      clear
      put(message)
      next
    elsif string =~ /^You.+struggle.+stand/
      clear
      fput 'stand'
      next
    elsif string =~ /stunned|can't do that while|cannot seem|^(?!You rummage).*can't seem|don't seem|Sorry, you may only type ahead/
      if dead?
        echo "You're dead...! You can't do that!"
        sleep 1
        script.downstream_buffer.unshift(string)
        return false
      elsif checkstunned
        while checkstunned
          sleep("0.25".to_f)
        end
      elsif checkwebbed
        while checkwebbed
          sleep("0.25".to_f)
        end
      elsif string =~ /Sorry, you may only type ahead/
        sleep 1
      else
        sleep 0.1
        script.downstream_buffer.unshift(string)
        return false
      end
      clear
      put(message)
      next
    else
      if waitingfor.empty?
        script.downstream_buffer.unshift(string)
        return string
      else
        if (foundit = waitingfor.find { |val| string =~ /#{val}/i })
          script.downstream_buffer.unshift(string)
          return foundit
        end
        sleep 1
        clear
        put(message)
        next
      end
    end
  end
end

# Sends messages to the game output.
#
# @param messages [Array<String>] The messages to send.
# @return [void]
# @example
#   put("Hello, World!")
def put(*messages)
  messages.each { |message| Game.puts(message) }
end

# Toggles the quiet mode of the current script.
#
# @return [void]
# @example
#   quiet_exit
def quiet_exit
  script = Script.current
  script.quiet = !(script.quiet)
end

# Matches input exactly against the provided strings.
#
# @param strings [Array<String>] The strings to match against the input.
# @return [String, Array<String>, false] The matched string or an array of matches, or false if no match is found.
# @raise [RuntimeError] If the current script context is unknown.
# @example
#   matchfindexact("hello?", "world?")
def matchfindexact(*strings)
  strings.flatten!
  unless (script = Script.current) then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting..."); Thread.current.kill; return false end
  if strings.empty? then echo("error! 'matchfind' with no strings to look for!"); sleep 1; return false end
  looking = Array.new
  strings.each { |str| looking.push(str.gsub('?', '(\b.+\b)')) }
  if looking.empty? then echo("matchfind without any strings to wait for!"); return false end
  regexpstr = looking.join('|')
  while (line_in = script.gets)
    if (gotit = line_in.slice(/#{regexpstr}/))
      matches = Array.new
      looking.each_with_index { |str, idx|
        if gotit =~ /#{str}/i
          strings[idx].count('?').times { |n| matches.push(eval("$#{n + 1}")) }
        end
      }
      break
    end
  end
  if matches.length == 1
    return matches.first
  else
    return matches.compact
  end
end

# Matches input against the provided strings and captures groups.
#
# @param strings [Array<String>] The strings to match against the input.
# @return [String, Array<String>] The captured groups from the match.
# @raise [RuntimeError] If the current script context is unknown.
# @example
#   matchfind("hello?", "world?")
def matchfind(*strings)
  regex = /#{strings.flatten.join('|').gsub('?', '(.+)')}/i
  unless (script = Script.current)
    respond "Unknown script is asking to use matchfind!  Cannot process request without identifying the calling script; killing this thread."
    Thread.current.kill
  end
  while true
    if (reobj = regex.match(script.gets))
      ret = reobj.captures.compact
      if ret.length < 2
        return ret.first
      else
        return ret
      end
    end
  end
end

# Matches input against the provided words and captures groups.
#
# @param strings [Array<String>] The words to match against the input.
# @return [String, Array<String>] The captured groups from the match.
# @raise [RuntimeError] If the current script context is unknown.
# @example
#   matchfindword("hello", "world")
def matchfindword(*strings)
  regex = /#{strings.flatten.join('|').gsub('?', '([\w\d]+)')}/i
  unless (script = Script.current)
    respond "Unknown script is asking to use matchfindword!  Cannot process request without identifying the calling script; killing this thread."
    Thread.current.kill
  end
  while true
    if (reobj = regex.match(script.gets))
      ret = reobj.captures.compact
      if ret.length < 2
        return ret.first
      else
        return ret
      end
    end
  end
end

# Sends messages to downstream scripts.
#
# @param messages [Array<String>] The messages to send.
# @return [Boolean] Returns true after sending messages.
# @example
#   send_scripts("message1", "message2")
def send_scripts(*messages)
  messages.flatten!
  messages.each { |message|
    Script.new_downstream(message)
  }
  true
end

# Inserts status tags for the current script based on the provided on/off parameter.
#
# @param onoff [String] Indicates whether to turn status tags "on" or "off". Default is "none".
# @return [void]
# @example
#   status_tags("on")
def status_tags(onoff = "none")
  script = Script.current
  if onoff == "on"
    script.want_downstream = false
    script.want_downstream_xml = true
    echo("Status tags will be sent to this script.")
  elsif onoff == "off"
    script.want_downstream = true
    script.want_downstream_xml = false
    echo("Status tags will no longer be sent to this script.")
  elsif script.want_downstream_xml
    script.want_downstream = true
    script.want_downstream_xml = false
  else
    script.want_downstream = false
    script.want_downstream_xml = true
  end
end

# Responds to the client with the provided messages.
#
# @param first [String, Array] The first message or an array of messages to send.
# @param messages [Array<String>] Additional messages to send.
# @return [void]
# @raise [StandardError] If an error occurs during message sending.
# @example
#   respond("Hello", "World")
def respond(first = "", *messages)
  str = ''
  begin
    if first.class == Array
      first.flatten.each { |ln| str += sprintf("%s\r\n", ln.to_s.chomp) }
    else
      str += sprintf("%s\r\n", first.to_s.chomp)
    end
    messages.flatten.each { |message| str += sprintf("%s\r\n", message.to_s.chomp) }
    str.split(/\r?\n/).each { |line| Script.new_script_output(line); Buffer.update(line, Buffer::SCRIPT_OUTPUT) }
    # str.gsub!(/\r?\n/, "\r\n") if $frontend == 'genie'
    if $frontend == 'stormfront' || $frontend == 'genie'
      str = "<output class=\"mono\"/>\r\n#{str.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')}<output class=\"\"/>\r\n"
    elsif $frontend == 'profanity'
      str = str.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
    end
    # Double-checked locking to avoid interrupting a stream and crashing the client
    str_sent = false
    if $_CLIENT_
      until str_sent
        wait_while { !XMLData.safe_to_respond? }
        str_sent = $_CLIENT_.puts_if(str) { XMLData.safe_to_respond? }
      end
    end
    if $_DETACHABLE_CLIENT_
      str_sent = false
      until str_sent
        wait_while { !XMLData.safe_to_respond? }
        begin
          str_sent = $_DETACHABLE_CLIENT_.puts_if(str) { XMLData.safe_to_respond? }
        rescue
          break
        end
      end
    end
  rescue
    puts $!
    puts $!.backtrace.first
  end
end

# Responds to the client with the provided messages, similar to `respond` but with a different internal handling.
#
# @param first [String, Array] The first message or an array of messages to send.
# @param messages [Array<String>] Additional messages to send.
# @return [void]
# @raise [StandardError] If an error occurs during message sending.
# @example
#   _respond("Hello", "World")
def _respond(first = "", *messages)
  str = ''
  begin
    if first.class == Array
      first.flatten.each { |ln| str += sprintf("%s\r\n", ln.to_s.chomp) }
    else
      str += sprintf("%s\r\n", first.to_s.chomp)
    end
    # str.gsub!(/\r?\n/, "\r\n") if $frontend == 'genie'
    messages.flatten.each { |message| str += sprintf("%s\r\n", message.to_s.chomp) }
    str.split(/\r?\n/).each { |line| Script.new_script_output(line); Buffer.update(line, Buffer::SCRIPT_OUTPUT) } # fixme: strip/separate script output?
    str_sent = false
    if $_CLIENT_
      until str_sent
        wait_while { !XMLData.safe_to_respond? }
        str_sent = $_CLIENT_.puts_if(str) { XMLData.safe_to_respond? }
      end
    end
    if $_DETACHABLE_CLIENT_
      str_sent = false
      until str_sent
        wait_while { !XMLData.safe_to_respond? }
        begin
          str_sent = $_DETACHABLE_CLIENT_.puts_if(str) { XMLData.safe_to_respond? }
        rescue
          break
        end
      end
    end
  rescue
    puts $!
    puts $!.backtrace.first
  end
end

# Calculates the pulse value for a noded character based on their profession and game state.
#
# @return [Integer] The calculated pulse value or 0 if the game is "DR".
# @example
#   pulse_value = noded_pulse
def noded_pulse
  unless XMLData.game =~ /DR/
    if Stats.prof =~ /warrior|rogue|sorcerer/i
      stats = [Skills.smc.to_i, Skills.emc.to_i]
    elsif Stats.prof =~ /empath|bard/i
      stats = [Skills.smc.to_i, Skills.mmc.to_i]
    elsif Stats.prof =~ /wizard/i
      stats = [Skills.emc.to_i, 0]
    elsif Stats.prof =~ /paladin|cleric|ranger/i
      stats = [Skills.smc.to_i, 0]
    else
      stats = [0, 0]
    end
    return (XMLData.max_mana * 25 / 100) + (stats.max / 10) + (stats.min / 20)
  else
    return 0 # this method is not used by DR
  end
end

# Calculates the pulse value for an unnoded character based on their profession and game state.
#
# @return [Integer] The calculated pulse value or 0 if the game is "DR".
# @example
#   pulse_value = unnoded_pulse
def unnoded_pulse
  unless XMLData.game =~ /DR/
    if Stats.prof =~ /warrior|rogue|sorcerer/i
      stats = [Skills.smc.to_i, Skills.emc.to_i]
    elsif Stats.prof =~ /empath|bard/i
      stats = [Skills.smc.to_i, Skills.mmc.to_i]
    elsif Stats.prof =~ /wizard/i
      stats = [Skills.emc.to_i, 0]
    elsif Stats.prof =~ /paladin|cleric|ranger/i
      stats = [Skills.smc.to_i, 0]
    else
      stats = [0, 0]
    end
    return (XMLData.max_mana * 15 / 100) + (stats.max / 10) + (stats.min / 20)
  else
    return 0 # this method is not used by DR
  end
end

require './lib/stash.rb'

# Empties both hands by calling the stash method.
#
# @return [void]
# @example
#   empty_hands
def empty_hands
  waitrt?
  Lich::Stash::stash_hands(both: true)
end

# Empties the hand that is less full based on the current state of the character's hands.
#
# @return [void]
# @example
#   empty_hand
def empty_hand
  right_hand = GameObj.right_hand
  left_hand = GameObj.left_hand

  unless (right_hand.id.nil? and ([Wounds.rightArm, Wounds.rightHand, Scars.rightArm, Scars.rightHand].max < 3)) or (left_hand.id.nil? and ([Wounds.leftArm, Wounds.leftHand, Scars.leftArm, Scars.leftHand].max < 3))
    if right_hand.id and ([Wounds.rightArm, Wounds.rightHand, Scars.rightArm, Scars.rightHand].max < 3 or [Wounds.leftArm, Wounds.leftHand, Scars.leftArm, Scars.leftHand].max == 3)
      waitrt?
      Lich::Stash::stash_hands(right: true)
    else
      waitrt?
      Lich::Stash::stash_hands(left: true)
    end
  end
end

# Empties the right hand by calling the stash method.
#
# @return [void]
# @example
#   empty_right_hand
def empty_right_hand
  waitrt?
  Lich::Stash::stash_hands(right: true)
end

# Empties the left hand by calling the stash method.
#
# @return [void]
# @example
#   empty_left_hand
def empty_left_hand
  waitrt?
  Lich::Stash::stash_hands(left: true)
end

# Fills both hands by calling the equip method.
#
# @return [void]
# @example
#   fill_hands
def fill_hands
  waitrt?
  Lich::Stash::equip_hands(both: true)
end

# Fills the hand based on the current state of the character's hands.
#
# @return [void]
# @example
#   fill_hand
def fill_hand
  waitrt?
  Lich::Stash::equip_hands()
end

# Fills the right hand by calling the equip method.
#
# @return [void]
# @example
#   fill_right_hand
def fill_right_hand
  waitrt?
  Lich::Stash::equip_hands(right: true)
end

# Fills the left hand by calling the equip method.
#
# @return [void]
# @example
#   fill_left_hand
def fill_left_hand
  waitrt?
  Lich::Stash::equip_hands(left: true)
end

# Executes a given action and waits for a success line in the output.
#
# @param action [String] The action to perform.
# @param success_line [Regexp] A regular expression to match the success line.
# @return [String] The line that matched the success line.
# @example
#   result = dothis("attack", /You hit/)
def dothis(action, success_line)
  loop {
    Script.current.clear
    put action
    loop {
      line = get
      if line =~ success_line
        return line
      elsif line =~ /^(\.\.\.w|W)ait ([0-9]+) sec(onds)?\.$/
        if $2.to_i > 1
          sleep($2.to_i - "0.5".to_f)
        else
          sleep 0.3
        end
        break
      elsif line == 'Sorry, you may only type ahead 1 command.'
        sleep 1
        break
      elsif line == 'You are still stunned.'
        wait_while { stunned? }
        break
      elsif line == 'That is impossible to do while unconscious!'
        100.times {
          unless (line = get?)
            sleep 0.1
          else
            break if line =~ /Your thoughts slowly come back to you as you find yourself lying on the ground\.  You must have been sleeping\.$|^You wake up from your slumber\.$/
          end
        }
        break
      elsif line == "You don't seem to be able to move to do that."
        100.times {
          unless (line = get?)
            sleep 0.1
          else
            break if line == 'The restricting force that envelops you dissolves away.'
          end
        }
        break
      elsif line == "You can't do that while entangled in a web."
        wait_while { checkwebbed }
        break
      elsif line == 'You find that impossible under the effects of the lullabye.'
        100.times {
          unless (line = get?)
            sleep 0.1
          else
            # fixme
            break if line == 'You shake off the effects of the lullabye.'
          end
        }
        break
      end
    }
  }
end

# Inserts a timeout mechanism for executing an action and waiting for a success line.
#
# @param action [String] the action to be performed
# @param timeout [Float] the maximum time to wait for the action to succeed
# @param success_line [Regexp] the regular expression to match a successful response
# @return [String, nil] the line that matches the success_line or nil if timeout occurs
# @note This method will continuously check for the success line until the timeout is reached.
# @example
#   result = dothistimeout("some_action", 5.0, /success/)
def dothistimeout(action, timeout, success_line)
  end_time = Time.now.to_f + timeout
  line = nil
  loop {
    Script.current.clear
    put action unless action.nil?
    loop {
      line = get?
      if line.nil?
        sleep 0.1
      elsif line =~ success_line
        return line
      elsif line =~ /^(\.\.\.w|W)ait ([0-9]+) sec(onds)?\.$/
        if $2.to_i > 1
          sleep($2.to_i - "0.5".to_f)
        else
          sleep 0.3
        end
        end_time = Time.now.to_f + timeout
        break
      elsif line == 'Sorry, you may only type ahead 1 command.'
        sleep 1
        end_time = Time.now.to_f + timeout
        break
      elsif line == 'You are still stunned.'
        wait_while { stunned? }
        end_time = Time.now.to_f + timeout
        break
      elsif line == 'That is impossible to do while unconscious!'
        100.times {
          unless (line = get?)
            sleep 0.1
          else
            break if line =~ /Your thoughts slowly come back to you as you find yourself lying on the ground\.  You must have been sleeping\.$|^You wake up from your slumber\.$/
          end
        }
        break
      elsif line == "You don't seem to be able to move to do that."
        100.times {
          unless (line = get?)
            sleep 0.1
          else
            break if line == 'The restricting force that envelops you dissolves away.'
          end
        }
        break
      elsif line == "You can't do that while entangled in a web."
        wait_while { checkwebbed }
        break
      elsif line == 'You find that impossible under the effects of the lullabye.'
        100.times {
          unless (line = get?)
            sleep 0.1
          else
            # fixme
            break if line == 'You shake off the effects of the lullabye.'
          end
        }
        break
      end
      if Time.now.to_f >= end_time
        return nil
      end
    }
  }
end

$link_highlight_start = ''
$link_highlight_end = ''
$speech_highlight_start = ''
$speech_highlight_end = ''

# Converts a line from the front-end format to a server-friendly format.
#
# @param line [String] the line to be converted
# @return [String, nil] the converted line or nil if the line is empty after conversion
# @raise [StandardError] logs any errors encountered during conversion
# @example
#   converted_line = fb_to_sf("<c>Some text</c>")
def fb_to_sf(line)
  begin
    return line if line == "\r\n"

    line = line.gsub(/<c>/, "")
    return nil if line.gsub("\r\n", '').length < 1

    return line
  rescue
    $_CLIENT_.puts "--- Error: fb_to_sf: #{$!}"
    $_CLIENT_.puts "$_SERVERSTRING_: #{$_SERVERSTRING_}"
    Lich.log("--- Error: fb_to_sf: #{$!}\n\t#{$!.backtrace.join("\n\t")}")
    Lich.log("$_SERVERSTRING_: #{$_SERVERSTRING_}")
    Lich.log("Line: #{line}")
  end
end

# Converts a line from server format to wizard format.
#
# @param line [String] the line to be converted
# @return [String, nil] the converted line or nil if the line is empty after conversion
# @raise [StandardError] logs any errors encountered during conversion
# @example
#   wizard_line = sf_to_wiz("<preset id='speech'>Hello</preset>")
def sf_to_wiz(line)
  begin
    return line if line == "\r\n"

    if $sftowiz_multiline
      $sftowiz_multiline = $sftowiz_multiline + line
      line = $sftowiz_multiline
    end
    if (line.scan(/<pushStream[^>]*\/>/).length > line.scan(/<popStream[^>]*\/>/).length)
      $sftowiz_multiline = line
      return nil
    end
    if (line.scan(/<style id="\w+"[^>]*\/>/).length > line.scan(/<style id=""[^>]*\/>/).length)
      $sftowiz_multiline = line
      return nil
    end
    $sftowiz_multiline = nil
    if line =~ /<LaunchURL src="(.*?)" \/>/
      $_CLIENT_.puts "\034GSw00005\r\nhttps://www.play.net#{$1}\r\n"
    end
    if line =~ /<preset id='speech'>(.*?)<\/preset>/m
      line = line.sub(/<preset id='speech'>.*?<\/preset>/m, "#{$speech_highlight_start}#{$1}#{$speech_highlight_end}")
    end
    if line =~ /<pushStream id="thoughts"[^>]*>\[([^\\]+?)\]\s*(.*?)<popStream\/>/m
      thought_channel = $1
      msg = $2
      thought_channel.gsub!(' ', '-')
      msg.gsub!('<pushBold/>', '')
      msg.gsub!('<popBold/>', '')
      line = line.sub(/<pushStream id="thoughts".*<popStream\/>/m, "You hear the faint thoughts of [#{thought_channel}]-ESP echo in your mind:\r\n#{msg}")
    end
    if line =~ /<pushStream id="voln"[^>]*>\[Voln \- (?:<a[^>]*>)?([A-Z][a-z]+)(?:<\/a>)?\]\s*(".*")[\r\n]*<popStream\/>/m
      line = line.sub(/<pushStream id="voln"[^>]*>\[Voln \- (?:<a[^>]*>)?([A-Z][a-z]+)(?:<\/a>)?\]\s*(".*")[\r\n]*<popStream\/>/m, "The Symbol of Thought begins to burn in your mind and you hear #{$1} thinking, #{$2}\r\n")
    end
    if line =~ /<stream id="thoughts"[^>]*>([^:]+): (.*?)<\/stream>/m
      line = line.sub(/<stream id="thoughts"[^>]*>.*?<\/stream>/m, "You hear the faint thoughts of #{$1} echo in your mind:\r\n#{$2}")
    end
    if line =~ /<pushStream id="familiar"[^>]*>(.*)<popStream\/>/m
      line = line.sub(/<pushStream id="familiar"[^>]*>.*<popStream\/>/m, "\034GSe\r\n#{$1}\034GSf\r\n")
    end
    if line =~ /<pushStream id="death"\/>(.*?)<popStream\/>/m
      line = line.sub(/<pushStream id="death"\/>.*?<popStream\/>/m, "\034GSw00003\r\n#{$1}\034GSw00004\r\n")
    end
    if line =~ /<style id="roomName" \/>(.*?)<style id=""\/>/m
      line = line.sub(/<style id="roomName" \/>.*?<style id=""\/>/m, "\034GSo\r\n#{$1}\034GSp\r\n")
    end
    line.gsub!(/<style id="roomDesc"\/><style id=""\/>\r?\n/, '')
    if line =~ /<style id="roomDesc"\/>(.*?)<style id=""\/>/m
      desc = $1.gsub(/<a[^>]*>/, $link_highlight_start).gsub("</a>", $link_highlight_end)
      line = line.sub(/<style id="roomDesc"\/>.*?<style id=""\/>/m, "\034GSH\r\n#{desc}\034GSI\r\n")
    end
    line = line.gsub("</prompt>\r\n", "</prompt>")
    line = line.gsub("<pushBold/>", "\034GSL\r\n")
    line = line.gsub("<popBold/>", "\034GSM\r\n")
    line = line.gsub(/<pushStream id=["'](?:spellfront|inv|bounty|society|speech|talk)["'][^>]*\/>.*?<popStream[^>]*>/m, '')
    line = line.gsub(/<stream id="Spells">.*?<\/stream>/m, '')
    line = line.gsub(/<(compDef|inv|component|right|left|spell|prompt)[^>]*>.*?<\/\1>/m, '')
    line = line.gsub(/<[^>]+>/, '')
    line = line.gsub('&gt;', '>')
    line = line.gsub('&lt;', '<')
    line = line.gsub('&amp;', '&')
    return nil if line.gsub("\r\n", '').length < 1

    return line
  rescue
    $_CLIENT_.puts "--- Error: sf_to_wiz: #{$!}"
    $_CLIENT_.puts "$_SERVERSTRING_: #{$_SERVERSTRING_}"
    Lich.log("--- Error: sf_to_wiz: #{$!}\n\t#{$!.backtrace.join("\n\t")}")
    Lich.log("$_SERVERSTRING_: #{$_SERVERSTRING_}")
    Lich.log("Line: #{line}")
  end
end

# Strips XML tags from a line based on the specified type.
#
# @param line [String] the line to be stripped of XML tags
# @param type [String] the type of content being processed (default: 'main')
# @return [String, nil] the stripped line or nil if the line is empty after stripping
# @note This method maintains state for multiline content based on the type.
# @example
#   clean_line = strip_xml("<pushStream>Some content</pushStream>")
def strip_xml(line, type: 'main')
  return line if line == "\r\n"

  if $strip_xml_multiline[type]
    $strip_xml_multiline[type] = $strip_xml_multiline[type] + line
    line = $strip_xml_multiline[type]
  end
  if (line.scan(/<pushStream[^>]*\/>/).length > line.scan(/<popStream[^>]*\/>/).length)
    $strip_xml_multiline ||= {}
    $strip_xml_multiline[type] = line
    return nil
  end
  $strip_xml_multiline[type] = nil

  line = line.gsub(/<pushStream id=["'](?:spellfront|inv|bounty|society|speech|talk)["'][^>]*\/>.*?<popStream[^>]*>/m, '')
  line = line.gsub(/<stream id="Spells">.*?<\/stream>/m, '')
  line = line.gsub(/<(compDef|inv|component|right|left|spell|prompt)[^>]*>.*?<\/\1>/m, '')
  line = line.gsub(/<[^>]+>/, '')
  line = line.gsub('&gt;', '>')
  line = line.gsub('&lt;', '<')

  return nil if line.gsub("\n", '').gsub("\r", '').gsub(' ', '').length < 1

  return line
end

# Returns the start sequence for bold text based on the frontend type.
#
# @return [String] the appropriate start sequence for bold text
# @example
#   start_sequence = monsterbold_start
def monsterbold_start
  if $frontend =~ /^(?:wizard|avalon)$/
    "\034GSL\r\n"
  elsif $frontend =~ /^(?:stormfront|frostbite|wrayth|profanity|genie)$/
    '<pushBold/>'
  else
    ''
  end
end

# Returns the end sequence for bold text based on the frontend type.
#
# @return [String] the appropriate end sequence for bold text
# @example
#   end_sequence = monsterbold_end
def monsterbold_end
  if $frontend =~ /^(?:wizard|avalon)$/
    "\034GSM\r\n"
  elsif $frontend =~ /^(?:stormfront|frostbite|wrayth|profanity|genie)$/
    '<popBold/>'
  else
    ''
  end
end

# Processes a client command string, executing the appropriate action based on the command.
#
# @param client_string [String] The command string received from the client.
# @return [nil] Returns nil if the command is not valid or if the command execution does not require a return value.
# @raise [ArgumentError] Raises an error if the command string is malformed.
# @example
#   do_client("<c>kill my_script")
def do_client(client_string)
  client_string.strip!
  #   Buffer.update(client_string, Buffer::UPSTREAM)
  client_string = UpstreamHook.run(client_string)
  #   Buffer.update(client_string, Buffer::UPSTREAM_MOD)
  return nil if client_string.nil?

  if client_string =~ /^(?:<c>)?#{$lich_char_regex}(.+)$/
    cmd = $1
    if cmd =~ /^k$|^kill$|^stop$/
      if Script.running.empty?
        respond '--- Lich: no scripts to kill'
      else
        Script.running.last.kill
      end
    elsif cmd =~ /^p$|^pause$/
      if (s = Script.running.reverse.find { |s_check| not s_check.paused? })
        s.pause
      else
        respond '--- Lich: no scripts to pause'
      end
      nil
    elsif cmd =~ /^u$|^unpause$/
      if (s = Script.running.reverse.find { |s_check| s_check.paused? })
        s.unpause
      else
        respond '--- Lich: no scripts to unpause'
      end
      nil
    elsif cmd =~ /^ka$|^kill\s?all$|^stop\s?all$/
      did_something = false
      Script.running.find_all { |s_check| not s_check.no_kill_all }.each { |s_check| s_check.kill; did_something = true }
      respond('--- Lich: no scripts to kill') unless did_something
    elsif cmd =~ /^pa$|^pause\s?all$/
      did_something = false
      Script.running.find_all { |s_check| not s_check.paused? and not s_check.no_pause_all }.each { |s_check| s_check.pause; did_something = true }
      respond('--- Lich: no scripts to pause') unless did_something
    elsif cmd =~ /^ua$|^unpause\s?all$/
      did_something = false
      Script.running.find_all { |s_check| s_check.paused? and not s_check.no_pause_all }.each { |s_check| s_check.unpause; did_something = true }
      respond('--- Lich: no scripts to unpause') unless did_something
    elsif cmd =~ /^(k|kill|stop|p|pause|u|unpause)\s(.+)/
      action = $1
      target = $2
      script = Script.running.find { |s_running| s_running.name == target } || Script.hidden.find { |s_hidden| s_hidden.name == target } || Script.running.find { |s_running| s_running.name =~ /^#{target}/i } || Script.hidden.find { |s_hidden| s_hidden.name =~ /^#{target}/i }
      if script.nil?
        respond "--- Lich: #{target} does not appear to be running! Use '#{$clean_lich_char}list' or '#{$clean_lich_char}listall' to see what's active."
      elsif action =~ /^(?:k|kill|stop)$/
        script.kill
      elsif action =~ /^(?:p|pause)$/
        script.pause
      elsif action =~ /^(?:u|unpause)$/
        script.unpause
      end
      target = nil
    elsif cmd =~ /^list\s?(?:all)?$|^l(?:a)?$/i
      if cmd =~ /a(?:ll)?/i
        list = Script.running + Script.hidden
      else
        list = Script.running
      end
      if list.empty?
        respond '--- Lich: no active scripts'
      else
        respond "--- Lich: #{list.collect { |active| active.paused? ? "#{active.name} (paused)" : active.name }.join(", ")}"
      end
      nil
    elsif cmd =~ /^force\s+[^\s]+/
      if cmd =~ /^force\s+([^\s]+)\s+(.+)$/
        Script.start($1, $2, :force => true)
      elsif cmd =~ /^force\s+([^\s]+)/
        Script.start($1, :force => true)
      end
    elsif cmd =~ /^send |^s /
      if cmd.split[1] == "to"
        script = (Script.running + Script.hidden).find { |scr| scr.name == cmd.split[2].chomp.strip } || script = (Script.running + Script.hidden).find { |scr| scr.name =~ /^#{cmd.split[2].chomp.strip}/i }
        if script
          msg = cmd.split[3..-1].join(' ').chomp
          if script.want_downstream
            script.downstream_buffer.push(msg)
          else
            script.unique_buffer.push(msg)
          end
          respond "--- sent to '#{script.name}': #{msg}"
        else
          respond "--- Lich: '#{cmd.split[2].chomp.strip}' does not match any active script!"
        end
        nil
      else
        if Script.running.empty? and Script.hidden.empty?
          respond('--- Lich: no active scripts to send to.')
        else
          msg = cmd.split[1..-1].join(' ').chomp
          respond("--- sent: #{msg}")
          Script.new_downstream(msg)
        end
      end
    elsif cmd =~ /^(?:exec|e)(q)? (.+)$/
      cmd_data = $2
      ExecScript.start(cmd_data, { :quiet => $1 })
    elsif cmd =~ /^(?:execname|en) ([\w\d-]+) (.+)$/
      execname = $1
      cmd_data = $2
      ExecScript.start(cmd_data, { :name => execname })
    elsif cmd =~ /^trust\s+(.*)/i
      script_name = $1
      if RUBY_VERSION =~ /^2\.[012]\./
        if File.exist?("#{SCRIPT_DIR}/#{script_name}.lic")
          if Script.trust(script_name)
            respond "--- Lich: '#{script_name}' is now a trusted script."
          else
            respond "--- Lich: '#{script_name}' is already trusted."
          end
        else
          respond "--- Lich: could not find script: #{script_name}"
        end
      else
        respond "--- Lich: this feature isn't available in this version of Ruby "
      end
    elsif cmd =~ /^(?:dis|un)trust\s+(.*)/i
      script_name = $1
      if RUBY_VERSION =~ /^2\.[012]\./
        if Script.distrust(script_name)
          respond "--- Lich: '#{script_name}' is no longer a trusted script."
        else
          respond "--- Lich: '#{script_name}' was not found in the trusted script list."
        end
      else
        respond "--- Lich: this feature isn't available in this version of Ruby "
      end
    elsif cmd =~ /^list\s?(?:un)?trust(?:ed)?$|^lt$/i
      if RUBY_VERSION =~ /^2\.[012]\./
        list = Script.list_trusted
        if list.empty?
          respond "--- Lich: no scripts are trusted"
        else
          respond "--- Lich: trusted scripts: #{list.join(', ')}"
        end
        nil
      else
        respond "--- Lich: this feature isn't available in this version of Ruby "
      end
    elsif cmd =~ /^set\s(.+)\s(on|off)/
      toggle_var = $1
      set_state = $2
      did_something = false
      begin
        Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values(?,?);", [toggle_var.to_s.encode('UTF-8'), set_state.to_s.encode('UTF-8')])
        did_something = true
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      respond("--- Lich: toggle #{toggle_var} set #{set_state}") if did_something
      did_something = false
      nil
    elsif cmd =~ /^hmr\s+(?<pattern>.*)/i
      begin
        HMR.reload %r{#{Regexp.last_match[:pattern]}}
      rescue ArgumentError
        if $!.to_s == 'invalid Unicode escape'
          respond "--- Lich: error: invalid Unicode escape"
          respond "--- Lich:   cmd: #{cmd}"
          respond "--- Lich: \\u is unicode escape, did you mean to use a / instead?"
        else
          respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
          Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
      end
    elsif XMLData.game =~ /^GS/ && cmd =~ /^infomon sync/i
      ExecScript.start("Infomon.sync", { :quiet => true })
    elsif XMLData.game =~ /^GS/ && cmd =~ /^infomon (?:reset|redo)!?/i
      ExecScript.start("Infomon.redo!", { :quiet => true })
    elsif XMLData.game =~ /^GS/ && cmd =~ /^infomon show( full)?/i
      case Regexp.last_match(1)
      when 'full'
        Infomon.show(true)
      else
        Infomon.show(false)
      end
    elsif XMLData.game =~ /^GS/ && cmd =~ /^infomon effects?(?: (true|false))?/i
      new_value = !(Infomon.get_bool("infomon.show_durations"))
      case Regexp.last_match(1)
      when 'true'
        new_value = true
      when 'false'
        new_value = false
      end
      respond "Changing Infomon's effect duration showing to #{new_value}"
      Infomon.set('infomon.show_durations', new_value)
    elsif XMLData.game =~ /^GS/ && cmd =~ /^sk\b(?: (add|rm|list|help)(?: ([\d\s]+))?)?/i
      SK.main(Regexp.last_match(1), Regexp.last_match(2))
    elsif XMLData.game =~ /^DR/ && cmd =~ /^display flaguid(?: (true|false))?/i
      new_value = !(Lich.hide_uid_flag)
      case Regexp.last_match(1)
      when 'true'
        new_value = true
      when 'false'
        new_value = false
      end
      respond "Changing Lich to NOT display Room Title RealIDs while FLAG ShowRoomID ON to #{new_value}"
      Lich.hide_uid_flag = new_value
    elsif cmd =~ /^display lichid(?: (true|false))?/i
      new_value = !(Lich.display_lichid)
      case Regexp.last_match(1)
      when 'true'
        new_value = true
      when 'false'
        new_value = false
      end
      respond "Changing Lich to display Lich ID#s to #{new_value}"
      Lich.display_lichid = new_value
    elsif cmd =~ /^display uid(?: (true|false))?/i
      new_value = !(Lich.display_uid)
      case Regexp.last_match(1)
      when 'true'
        new_value = true
      when 'false'
        new_value = false
      end
      respond "Changing Lich to display RealID#s to #{new_value}"
      Lich.display_uid = new_value
    elsif cmd =~ /^display exits?(?: (true|false))?/i
      new_value = !(Lich.display_exits)
      case Regexp.last_match(1)
      when 'true'
        new_value = true
      when 'false'
        new_value = false
      end
      respond "Changing Lich to display Room Exits of non-StringProc/Obvious exits to #{new_value}"
      Lich.display_exits = new_value
    elsif cmd =~ /^display stringprocs?(?: (true|false))?/i
      new_value = !(Lich.display_stringprocs)
      case Regexp.last_match(1)
      when 'true'
        new_value = true
      when 'false'
        new_value = false
      end
      respond "Changing Lich to display Room Exits of StringProcs to #{new_value}"
      Lich.display_stringprocs = new_value
    elsif cmd =~ /^(?:lich5-update|l5u)\s+(.*)/i
      update_parameter = $1.dup
      Lich::Util::Update.request("#{update_parameter}")
    elsif cmd =~ /^(?:lich5-update|l5u)/i
      Lich::Util::Update.request("--help")
    elsif cmd =~ /^banks$/ && XMLData.game =~ /^GS/
      Game._puts "<c>bank account"
      $_CLIENTBUFFER_.push "<c>bank account"
    elsif cmd =~ /^magic$/ && XMLData.game =~ /^GS/
      Effects.display
    elsif cmd =~ /^help$/i
      respond
      respond "Lich v#{LICH_VERSION}"
      respond
      respond 'built-in commands:'
      respond "   #{$clean_lich_char}<script name>             start a script"
      respond "   #{$clean_lich_char}force <script name>       start a script even if it's already running"
      respond "   #{$clean_lich_char}pause <script name>       pause a script"
      respond "   #{$clean_lich_char}p <script name>           ''"
      respond "   #{$clean_lich_char}unpause <script name>     unpause a script"
      respond "   #{$clean_lich_char}u <script name>           ''"
      respond "   #{$clean_lich_char}kill <script name>        kill a script"
      respond "   #{$clean_lich_char}k <script name>           ''"
      respond "   #{$clean_lich_char}pause                     pause the most recently started script that isn't aready paused"
      respond "   #{$clean_lich_char}p                         ''"
      respond "   #{$clean_lich_char}unpause                   unpause the most recently started script that is paused"
      respond "   #{$clean_lich_char}u                         ''"
      respond "   #{$clean_lich_char}kill                      kill the most recently started script"
      respond "   #{$clean_lich_char}k                         ''"
      respond "   #{$clean_lich_char}list                      show running scripts (except hidden ones)"
      respond "   #{$clean_lich_char}l                         ''"
      respond "   #{$clean_lich_char}pause all                 pause all scripts"
      respond "   #{$clean_lich_char}pa                        ''"
      respond "   #{$clean_lich_char}unpause all               unpause all scripts"
      respond "   #{$clean_lich_char}ua                        ''"
      respond "   #{$clean_lich_char}kill all                  kill all scripts"
      respond "   #{$clean_lich_char}ka                        ''"
      respond "   #{$clean_lich_char}list all                  show all running scripts"
      respond "   #{$clean_lich_char}la                        ''"
      respond
      respond "   #{$clean_lich_char}exec <code>               executes the code as if it was in a script"
      respond "   #{$clean_lich_char}e <code>                  ''"
      respond "   #{$clean_lich_char}execq <code>              same as #{$clean_lich_char}exec but without the script active and exited messages"
      respond "   #{$clean_lich_char}eq <code>                 ''"
      respond "   #{$clean_lich_char}execname <name> <code>    creates named exec (name#) and then executes the code as if it was in a script"
      respond
      if (RUBY_VERSION =~ /^2\.[012]\./)
        respond "   #{$clean_lich_char}trust <script name>       let the script do whatever it wants"
        respond "   #{$clean_lich_char}distrust <script name>    restrict the script from doing things that might harm your computer"
        respond "   #{$clean_lich_char}list trusted              show what scripts are trusted"
        respond "   #{$clean_lich_char}lt                        ''"
        respond
      end
      respond "   #{$clean_lich_char}send <line>               send a line to all scripts as if it came from the game"
      respond "   #{$clean_lich_char}send to <script> <line>   send a line to a specific script"
      respond
      respond "   #{$clean_lich_char}set <variable> [on|off]   set a global toggle variable on or off"
      respond "   #{$clean_lich_char}lich5-update --<command>  Lich5 ecosystem management "
      respond "                              see #{$clean_lich_char}lich5-update --help"
      respond "   #{$clean_lich_char}hmr <regex filepath>      Hot module reload a Ruby or Lich5 file without relogging, uses Regular Expression matching"
      if XMLData.game =~ /^GS/
        respond
        respond "   #{$clean_lich_char}infomon sync              sends all the various commands to resync character data for infomon (fixskill)"
        respond "   #{$clean_lich_char}infomon reset             resets entire character infomon db table and then syncs data (fixprof)"
        respond "   #{$clean_lich_char}infomon effects           toggle display of effect durations"
        respond "   #{$clean_lich_char}infomon show              shows all current Infomon values for character"
        respond "   #{$clean_lich_char}sk help                   show information on modifying self-knowledge spells to be known"
      elsif XMLData.game =~ /^DR/
        respond "   #{$clean_lich_char}display flaguid           toggle display of RealID in Room Title with FLAG ShowRoomID (required for Lich5 to be ON)"
      end
      respond "   #{$clean_lich_char}display lichid            toggle display of Lich Map# when displaying room information"
      respond "   #{$clean_lich_char}display uid               toggle display of RealID Map# when displaying room information"
      respond "   #{$clean_lich_char}display exits             toggle display of non-StringProc/Obvious exits known for room in mapdb"
      respond "   #{$clean_lich_char}display stringprocs       toggle display of StringProc exits known for room in mapdb if timeto is valid"
      respond
      respond 'If you liked this help message, you might also enjoy:'
      respond "   #{$clean_lich_char}lnet help" if defined?(LNet)
      respond "   #{$clean_lich_char}go2 help"
      respond "   #{$clean_lich_char}repository help"
      respond "   #{$clean_lich_char}alias help"
      respond "   #{$clean_lich_char}vars help"
      respond "   #{$clean_lich_char}autostart help"
      respond
    else
      if cmd =~ /^([^\s]+)\s+(.+)/
        Script.start($1, $2)
      else
        Script.start(cmd)
      end
    end
  else
    if $offline_mode
      respond "--- Lich: offline mode: ignoring #{client_string}"
    else
      client_string = "#{$cmd_prefix}bbs" if ($frontend =~ /^(?:wizard|avalon)$/) and (client_string == "#{$cmd_prefix}\egbbk\n") # launch forum
      Game._puts client_string
    end
    $_CLIENTBUFFER_.push client_string
  end
  Script.new_upstream(client_string)
end

# Reports errors that occur during the execution of the given block.
#
# @param [Proc] block The block of code to execute.
# @return [nil] Returns nil if a SystemExit is raised.
# @raise [StandardError] Logs and responds to any standard error that occurs.
# @raise [SyntaxError] Logs and responds to syntax errors.
# @raise [SecurityError] Logs and responds to security errors.
# @raise [ThreadError] Logs and responds to thread errors.
# @raise [SystemStackError] Logs and responds to system stack errors.
# @raise [LoadError] Logs and responds to load errors.
# @raise [NoMemoryError] Logs and responds to memory errors.
# @example
#   report_errors do
#     # some code that may raise an error
#   end
def report_errors(&block)
  begin
    block.call
  rescue
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue SyntaxError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue SystemExit
    nil
  rescue SecurityError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue ThreadError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue SystemStackError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue StandardError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  #  rescue ScriptError
  #    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
  #    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue LoadError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue NoMemoryError
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  rescue
    respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
  end
end

# Displays a deprecation warning for the alias command.
#
# @return [void] This method does not return a value.
# @example
#   alias_deprecated
def alias_deprecated
  # todo: add command reference, possibly add calling script
  echo "The alias command you're attempting to use is deprecated.  Fix your script."
end

## Alias block from Lich (needs further cleanup)

undef :abort
alias :mana :checkmana
alias :mana? :checkmana
alias :max_mana :maxmana
alias :health :checkhealth
alias :health? :checkhealth
alias :spirit :checkspirit
alias :spirit? :checkspirit
alias :stamina :checkstamina
alias :stamina? :checkstamina
alias :stunned? :checkstunned
alias :bleeding? :checkbleeding
alias :reallybleeding? :alias_deprecated
alias :poisoned? :checkpoison
alias :diseased? :checkdisease
alias :dead? :checkdead
alias :hiding? :checkhidden
alias :hidden? :checkhidden
alias :hidden :checkhidden
alias :checkhiding :checkhidden
alias :invisible? :checkinvisible
alias :standing? :checkstanding
alias :kneeling? :checkkneeling
alias :sitting? :checksitting
alias :stance? :checkstance
alias :stance :checkstance
alias :joined? :checkgrouped
alias :checkjoined :checkgrouped
alias :group? :checkgrouped
alias :myname? :checkname
alias :active? :checkspell
alias :righthand? :checkright
alias :lefthand? :checkleft
alias :righthand :checkright
alias :lefthand :checkleft
alias :mind? :checkmind
alias :checkactive :checkspell
alias :forceput :fput
alias :send_script :send_scripts
alias :stop_scripts :stop_script
alias :kill_scripts :stop_script
alias :kill_script :stop_script
alias :fried? :checkfried
alias :saturated? :checksaturated
alias :webbed? :checkwebbed
alias :pause_scripts :pause_script
alias :roomdescription? :checkroomdescrip
alias :prepped? :checkprep
alias :checkprepared :checkprep
alias :unpause_scripts :unpause_script
alias :priority? :setpriority
alias :checkoutside :outside?
alias :toggle_status :status_tags
alias :encumbrance? :checkencumbrance
alias :bounty? :checkbounty
