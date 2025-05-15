# Module for handling currency and money-related operations in DragonRealms
# Provides functionality for currency conversion, bank operations, and wealth management
#
# @author Lich5 Documentation Generator
module Lich
  module DragonRealms
    module DRCM
      module_function

      # Map of regular expressions for matching coin denomination abbreviations
      # @return [Hash<String, Regexp>] Map of denomination names to matching patterns
      $DENOMINATION_REGEX_MAP = {
        'platinum' => /\bp(l|la|lat|lati|latin|latinu|latinum)?\b/i,
        'gold'     => /\bg(o|ol|old)?\b/i,
        'silver'   => /\bs(i|il|ilv|ilve|ilver)?\b/i,
        'bronze'   => /\bb(r|ro|ron|ronz|ronze)?\b/i,
        'copper'   => /\bc(o|op|opp|oppe|opper)?\b/i
      }

      # Map of regular expressions for matching currency type abbreviations
      # @return [Hash<String, Regexp>] Map of currency names to matching patterns
      $CURRENCY_REGEX_MAP = {
        'kronars' => /\bk(r|ro|ron|rona|ronar|ronars)?\b/i,
        'lirums'  => /\bl(i|ir|iru|irum|irums)?\b/i,
        'dokoras' => /\bd(o|ok|oko|okor|okora|okoras)?\b/i
      }

      # Converts a copper amount into an optimal distribution of coin denominations
      #
      # @param copper [Integer] Amount in copper to minimize
      # @return [Array<String>] Array of strings describing coin amounts (e.g. ["1 platinum", "5 gold"])
      # @example
      #   DRCM.minimize_coins(15783) #=> ["1 platinum", "5 gold", "7 silver", "8 copper"]
      def minimize_coins(copper)
        denominations = [[10_000, 'platinum'], [1000, 'gold'], [100, 'silver'], [10, 'bronze'], [1, 'copper']]
        denominations.inject([copper, []]) do |result, denomination|
          remaining = result.first
          display = result.last
          if remaining / denomination.first > 0
            display << "#{remaining / denomination.first} #{denomination.last}"
          end
          [remaining % denomination.first, display]
        end.last
      end

      # Converts an amount in a given denomination to its copper equivalent
      #
      # @param amount [Numeric] The amount to convert
      # @param denomination [String] The denomination to convert from (platinum, gold, silver, bronze, copper)
      # @return [Integer] The equivalent amount in copper
      # @example
      #   DRCM.convert_to_copper(1.5, "platinum") #=> 15000
      def convert_to_copper(amount, denomination)
        denomination = denomination.strip
        if !denomination.empty?
          return (amount.to_f * 10_000).to_i if 'platinum'.start_with?(denomination.downcase)
          return (amount.to_f * 1000).to_i if 'gold'.start_with?(denomination.downcase)
          return (amount.to_f * 100).to_i if 'silver'.start_with?(denomination.downcase)
          return (amount.to_f * 10).to_i if 'bronze'.start_with?(denomination.downcase)
          return (amount.to_f * 1).to_i if 'copper'.start_with?(denomination.downcase)
        end
        DRC.message("Unknown denomination, assuming coppers: #{denomination}")
        amount.to_i
      end

      # Gets the full canonical currency name from an abbreviation
      #
      # @param currency [String] Currency abbreviation
      # @return [String, nil] Full currency name or nil if not found
      # @example
      #   DRCM.get_canonical_currency("kro") #=> "kronars"
      def get_canonical_currency(currency)
        currencies = [
          'kronars',
          'lirums',
          'dokoras'
        ]
        return currencies.find { |x| x.start_with?(currency) }
      end

      # Converts an amount between different currencies with exchange fee
      #
      # @param amount [Integer] Amount to convert
      # @param from [String] Source currency
      # @param to [String] Target currency  
      # @param fee [Float] Exchange fee percentage (negative for buying, positive for selling)
      # @return [Integer] Converted amount after fees
      # @example
      #   DRCM.convert_currency(100, "kronars", "dokoras", -0.05) #=> 72
      def convert_currency(amount, from, to, fee)
        exchange_rates = {
          'dokoras' => {
            'dokoras' => 1,
            'kronars' => 1.385808991,
            'lirums'  => 1.108646953
          },
          'kronars' => {
            'dokoras' => 0.7216,
            'kronars' => 1,
            'lirums'  => 0.8
          },
          'lirums'  => {
            'dokoras' => 0.902,
            'kronars' => 1.25,
            'lirums'  => 1
          }
        }
        if fee < 0
          ((amount / exchange_rates[from][to]).ceil / (1 + fee)).ceil
        else
          ((amount * exchange_rates[from][to]).ceil * (1 - fee)).floor
        end
      end

      # Gets the primary currency for a given hometown
      #
      # @param hometown_name [String] Name of the hometown
      # @return [String] Currency name for that hometown
      def hometown_currency(hometown_name)
        get_data('town')[hometown_name]['currency']
      end

      # Checks current wealth in a specific currency
      #
      # @param currency [String] Currency to check
      # @return [Integer] Amount owned in copper value
      def check_wealth(currency)
        DRC.bput("wealth #{currency}", /\(\d+ copper #{currency}\)/i, /No #{currency}/i).scan(/\d+/).first.to_i
      end

      # Gets current wealth for a hometown's currency
      #
      # @param hometown [String] Hometown name
      # @return [Integer] Amount owned in copper value
      def wealth(hometown)
        check_wealth(hometown_currency(hometown))
      end

      # Gets total wealth across all currencies
      #
      # @return [Hash<String,Integer>] Hash mapping currency names to copper values
      # @example
      #   DRCM.get_total_wealth #=> {"kronars" => 1000, "lirums" => 500, "dokoras" => 750}
      def get_total_wealth
        kronars = 0
        lirums = 0
        dokoras = 0

        DRC.bput("wealth", "Wealth")
        pause 0.5
        wealth_lines = reget(10).map(&:strip).reverse

        wealth_lines.each do |line|
          case line
          when /^Wealth:/i
            break
          when /\(\d+ copper Kronars\)/i
            kronars = line.scan(/\((\d+) copper kronars\)/i).first.first.to_i
          when /\(\d+ copper Lirums\)/i
            lirums = line.scan(/\((\d+) copper lirums\)/i).first.first.to_i
          when /\(\d+ copper Dokoras\)/i
            dokoras = line.scan(/\((\d+) copper dokoras\)/i).first.first.to_i
          end
        end

        total_wealth = {
          'kronars' => kronars,
          'lirums'  => lirums,
          'dokoras' => dokoras
        }
        return total_wealth
      end

      # Ensures a minimum amount of copper is available, withdrawing if needed
      #
      # @param copper [Integer] Required copper amount
      # @param settings [Object] Character settings object
      # @param hometown [String, nil] Optional hometown override
      # @return [Boolean] True if successful, false if failed
      def ensure_copper_on_hand(copper, settings, hometown = nil)
        hometown = settings.hometown if hometown == nil

        on_hand = wealth(hometown)
        return true if on_hand >= copper

        withdrawals = minimize_coins(copper - on_hand)

        withdrawals.all? { |amount| withdraw_exact_amount?(amount, settings, hometown) }
      end

      # Withdraws an exact amount from the bank
      #
      # @param amount_as_string [String] Amount to withdraw (e.g. "1 platinum")
      # @param settings [Object] Character settings object
      # @param hometown [String, nil] Optional hometown override
      # @return [Boolean] True if successful, false if failed
      def withdraw_exact_amount?(amount_as_string, settings, hometown = nil)
        hometown = settings.hometown if hometown == nil

        if settings.bankbot_enabled
          DRCT.walk_to(settings.bankbot_room_id)
          DRC.release_invisibility
          if DRRoom.pcs.include?(settings.bankbot_name)
            amount_convert, type = amount_as_string.split
            amount = convert_to_copper(amount_convert, type)
            currency = hometown_currency(settings.hometown)
            case DRC.bput("whisper #{settings.bankbot_name} withdraw #{amount} #{currency}", 'offers you', 'Whisper what to who?')
            when 'offers you'
              DRC.bput('accept tip', 'Your current balance is')
            end
          else
            get_money_from_bank(amount_as_string, settings, hometown)
          end
        else
          get_money_from_bank(amount_as_string, settings, hometown)
        end
      end

      # Withdraws money directly from a bank
      #
      # @param amount_as_string [String] Amount to withdraw
      # @param settings [Object] Character settings object
      # @param hometown [String, nil] Optional hometown override
      # @return [Boolean] True if successful, false if failed
      def get_money_from_bank(amount_as_string, settings, hometown = nil)
        hometown = settings.hometown if hometown == nil

        DRCT.walk_to(get_data('town')[hometown]['deposit']['id'])
        DRC.release_invisibility
        loop do
          case DRC.bput("withdraw #{amount_as_string}", 'The clerk counts', 'The clerk tells',
                        'The clerk glares at you.', 'You count out', 'find a new deposit jar', 'If you value your hands',
                        'Hey!  Slow down!', "You must be at a bank teller's window to withdraw money",
                        "You don't have that much money", 'have an account',
                        /The clerk says, "I'm afraid you can't withdraw that much at once/,
                        /^How much do you wish to withdraw/i)
          when 'The clerk counts', 'You count out'
            break true
          when 'The clerk glares at you.', 'Hey!  Slow down!', "I don't know what you think you're doing"
            pause 15
          when 'The clerk tells', 'If you value your hands', 'find a new deposit jar',
            "You must be at a bank teller's window to withdraw money", "You don't have that much money",
            'have an account', /The clerk says, "I'm afraid you can't withdraw that much at once/,
            /^How much do you wish to withdraw/i
            break false
          else
            break false
          end
        end
      end

      # Gets current debt in hometown currency
      #
      # @param hometown [String] Hometown name
      # @return [Integer] Current debt amount
      def debt(hometown)
        currency = hometown_currency(hometown)
        DRC.bput('wealth', /\(\d+ copper #{currency}\)/i, /Wealth:/i).scan(/\d+/).first.to_i
      end

      # Deposits coins while keeping a minimum amount
      #
      # @param keep_copper [Integer] Amount of copper to keep
      # @param settings [Object] Character settings object
      # @param hometown [String, nil] Optional hometown override
      # @return [Array<Integer,String>, nil] Array of [balance, currency] or nil if failed
      def deposit_coins(keep_copper, settings, hometown = nil)
        return if settings.skip_bank

        hometown = settings.hometown if hometown == nil

        DRCT.walk_to(get_data('town')[hometown]['deposit']['id'])
        DRC.release_invisibility
        DRC.bput('wealth', 'Wealth:')
        case DRC.bput('deposit all', 'you drop all your', 'You hand the clerk some coins', "You don't have any", 'There is no teller here', 'reached the maximum balance I can permit', 'You find your jar with little effort', 'Searching methodically through the shelves')
        when 'There is no teller here'
          return
        end
        minimize_coins(keep_copper).each { |amount| withdraw_exact_amount?(amount, settings) } if settings.hometown == hometown
        case DRC.bput('check balance', /current balance is .*? (?:Kronars?|Dokoras?|Lirums?)\."$/,
                      /If you would like to open one, you need only deposit a few (?:Kronars?|Dokoras?|Lirums?)\."$/,
                      /As expected, there are .*? (?:Kronars?|Dokoras?|Lirums?)\.$/,
                      'Perhaps you should find a new deposit jar for your financial needs.  Be sure to mark it with your name')
        when /current balance is (?<balance>.*?) (?<currency>Kronars?|Dokoras?|Lirums?)\."$/,
             /As expected, there are (?<balance>.*?) (?<currency>Kronars?|Dokoras?|Lirums?)\.$/
          currency = Regexp.last_match(:currency)
          balance = 0
          Regexp.last_match(:balance).gsub(/and /, '').split(', ').each do |amount_as_string|
            amount, denomination = amount_as_string.split()
            balance += convert_to_copper(amount, denomination)
          end
        when /If you would like to open one, you need only deposit a few (?<currency>Kronars?|Dokoras?|Lirums?)\."$/
          balance = 0
          currency = Regexp.last_match(:currency)
        when /Perhaps you should find a new deposit jar/
          balance = 0
          currency = 'Dokoras'
        end
        return balance, currency
      end

      # Gets the currency for a specific town
      #
      # @param town [String] Town name
      # @return [String] Currency name for that town
      def town_currency(town)
        get_data('town')[town]['currency']
      end
    end
  end
end