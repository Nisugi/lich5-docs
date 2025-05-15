# Module containing functionality specific to DragonRealms game mechanics and parsing
#
# @author Lich5 Documentation Generator
module Lich
  module DragonRealms
    # Converts currency amounts to copper pieces based on denomination
    #
    # @param amt [Integer] The amount to convert
    # @param denomination [String] The currency denomination ('platinum', 'gold', 'silver', 'bronze', 'copper')
    # @return [Integer] The equivalent amount in copper pieces
    # @example
    #   convert2copper(5, 'platinum') #=> 50000
    #   convert2copper(10, 'gold') #=> 10000
    def convert2copper(amt, denomination)
      if denomination =~ /platinum/
        (amt.to_i * 10_000)
      elsif denomination =~ /gold/
        (amt.to_i * 1000)
      elsif denomination =~ /silver/
        (amt.to_i * 100)
      elsif denomination =~ /bronze/
        (amt.to_i * 10)
      else
        amt
      end
    end

    # Checks for active experience modifiers
    #
    # @return [String] Raw game output showing active experience modifiers
    # @example
    #   check_exp_mods #=> "The following skills are currently under the influence..."
    def check_exp_mods
      Lich::Util.issue_command("exp mods", /The following skills are currently under the influence of a modifier/, /^<output class=""/, quiet: true, include_end: false, usexml: false)
    end

    # Converts copper pieces into a formatted string showing amounts in all denominations
    #
    # @param copper [Integer] Amount in copper pieces
    # @return [String] Formatted string showing amounts in platinum, gold, silver, bronze and copper
    # @example
    #   convert2plats(54321) #=> "5 platinum, 4 gold, 3 silver, 2 bronze, 1 copper"
    def convert2plats(copper)
      denominations = [[10_000, 'platinum'], [1000, 'gold'], [100, 'silver'], [10, 'bronze'], [1, 'copper']]
      denominations.inject([copper, []]) do |result, denomination|
        remaining = result.first
        display = result.last
        if remaining / denomination.first > 0
          display << "#{remaining / denomination.first} #{denomination.last}"
        end
        [remaining % denomination.first, display]
      end.last.join(', ')
    end

    # Cleans and splits room object descriptions into individual items
    #
    # @param room_objs [String] Raw room objects description
    # @return [Array<String>] Array of individual object descriptions
    # @example
    #   clean_and_split("You also see a sword and a shield") #=> ["a sword", "a shield"]
    def clean_and_split(room_objs)
      room_objs.sub(/You also see/, '').sub(/ with a [\w\s]+ sitting astride its back/, '').strip.split(/,|\sand\s/)
    end

    # Extracts player character names from room description
    #
    # @param room_players [String] Raw room players description
    # @return [Array<String>] Array of player character names
    # @example
    #   find_pcs("Bob who is standing and Jim who is sitting") #=> ["Bob", "Jim"]
    def find_pcs(room_players)
      room_players.sub(/ and (.*)$/) { ", #{Regexp.last_match(1)}" }
                  .split(', ')
                  .map { |obj| obj.sub(/ (who|whose body)? ?(has|is|appears|glows) .+/, '').sub(/ \(.+\)/, '') }
                  .map { |obj| obj.strip.scan(/\w+$/).first }
    end

    # Finds prone (lying down) player characters in room
    #
    # @param room_players [String] Raw room players description
    # @return [Array<String>] Array of prone player character names
    # @example
    #   find_pcs_prone("Bob who is lying down and Jim who is standing") #=> ["Bob"]
    def find_pcs_prone(room_players)
      room_players.sub(/ and (.*)$/) { ", #{Regexp.last_match(1)}" }
                  .split(', ')
                  .select { |obj| obj =~ /who is lying down/i }
                  .map { |obj| obj.sub(/ who (has|is) .+/, '').sub(/ \(.+\)/, '') }
                  .map { |obj| obj.strip.scan(/\w+$/).first }
    end

    # Finds sitting player characters in room
    #
    # @param room_players [String] Raw room players description
    # @return [Array<String>] Array of sitting player character names
    # @example
    #   find_pcs_sitting("Bob who is standing and Jim who is sitting") #=> ["Jim"]
    def find_pcs_sitting(room_players)
      room_players.sub(/ and (.*)$/) { ", #{Regexp.last_match(1)}" }
                  .split(', ')
                  .select { |obj| obj =~ /who is sitting/i }
                  .map { |obj| obj.sub(/ who (has|is) .+/, '').sub(/ \(.+\)/, '') }
                  .map { |obj| obj.strip.scan(/\w+$/).first }
    end

    # Finds all NPCs (including dead ones) in room description
    #
    # @param room_objs [String] Raw room objects description
    # @return [Array<String>] Array of NPC descriptions with XML tags
    # @example
    #   find_all_npcs("You also see <pushBold/>goblin<popBold/>") #=> ["<pushBold/>goblin<popBold/>"]
    def find_all_npcs(room_objs)
      room_objs.sub(/You also see/, '').sub(/ with a [\w\s]+ sitting astride its back/, '').strip
               .scan(%r{<pushBold/>[^<>]*<popBold/> which appears dead|<pushBold/>[^<>]*<popBold/> \(dead\)|<pushBold/>[^<>]*<popBold/>})
    end

    # Cleans and formats NPC descriptions
    #
    # @param npc_string [Array<String>] Array of raw NPC descriptions
    # @return [Array<String>] Array of cleaned NPC names with ordinals for duplicates
    # @example
    #   clean_npc_string(["<pushBold/>goblin<popBold/>", "<pushBold/>goblin<popBold/>"]) 
    #   #=> ["goblin", "second goblin"]
    def clean_npc_string(npc_string)
      tmp_npc_string = npc_string.map { |obj| obj.sub(/.*alfar warrior.*/, 'alfar warrior') }
                                 .map { |obj| obj.sub(/.*sinewy leopard.*/, 'sinewy leopard') }
                                 .map { |obj| obj.sub(/.*lesser naga.*/, 'lesser naga') }
                                 .map { |obj| obj.sub('<pushBold/>', '').sub(%r{<popBold/>.*}, '') }
                                 .map { |obj| obj.split(/\sand\s/).last.sub(/(?:\sglowing)?\swith\s.*/, '') }
                                 .map { |obj| obj.strip.scan(/[A-z'-]+$/).first }
                                 .sort
      flat_npcs = []
      tmp_npc_string.uniq.each { |npc| flat_npcs << tmp_npc_string.size.times.select { |i| tmp_npc_string[i] == npc }.size.times.map { |number| number.zero? ? tmp_npc_string[0] : tmp_npc_string[number].sub(npc, "#{$ORDINALS[number]} #{npc}") } }
      flat_npcs.flatten
    end

    # Finds live NPCs in room description
    #
    # @param room_objs [String] Raw room objects description
    # @return [Array<String>] Array of live NPC names
    # @example
    #   find_npcs("You also see <pushBold/>goblin<popBold/>") #=> ["goblin"]
    def find_npcs(room_objs)
      npcs = find_all_npcs(room_objs).reject { |obj| obj =~ /which appears dead|\(dead\)/ }
      clean_npc_string(npcs)
    end

    # Finds dead NPCs in room description
    #
    # @param room_objs [String] Raw room objects description
    # @return [Array<String>] Array of dead NPC names
    # @example
    #   find_dead_npcs("You also see <pushBold/>goblin<popBold/> which appears dead") #=> ["goblin"]
    def find_dead_npcs(room_objs)
      dead_npcs = find_all_npcs(room_objs).select { |obj| obj =~ /which appears dead|\(dead\)/ }
      clean_npc_string(dead_npcs)
    end

    # Finds non-NPC objects in room description
    #
    # @param room_objs [String] Raw room objects description
    # @return [Array<String>] Array of object names
    # @note Removes articles (a, an, some) and periods from object names
    # @example
    #   find_objects("You also see a sword.") #=> ["sword"]
    def find_objects(room_objs)
      room_objs.sub!("<pushBold/>a domesticated gelapod<popBold/>", 'domesticated gelapod')
      clean_and_split(room_objs)
        .reject { |obj| obj =~ /pushBold/ }
        .map { |obj| obj.sub(/\.$/, '').strip.sub(/^a /, '').strip.sub(/^some /, '') }
    end
  end
end