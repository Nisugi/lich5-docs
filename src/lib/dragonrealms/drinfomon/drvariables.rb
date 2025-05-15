# Module containing DragonRealms-specific constants and data structures used by the Lich scripting system
# for interacting with the DragonRealms game.
#
# @author Lich5 Documentation Generator
module Lich
  module DragonRealms
    # Array of learning rate descriptions in ascending order of skill absorption
    # from lowest ('clear') to highest ('mind lock')
    #
    # @return [Array<String>] Array of learning rate descriptions
    DR_LEARNING_RATES = [
      'clear',
      'dabbling',
      'perusing',
      'learning',
      'thoughtful',
      'thinking',
      'considering',
      'pondering',
      'ruminating',
      'concentrating',
      'attentive',
      'deliberative',
      'interested',
      'examining',
      'understanding',
      'absorbing',
      'intrigued',
      'scrutinizing',
      'analyzing',
      'studious',
      'focused',
      'very focused',
      'engaged',
      'very engaged',
      'cogitating',
      'fascinated',
      'captivated',
      'engrossed',
      'riveted',
      'very riveted',
      'rapt',
      'very rapt',
      'enthralled',
      'nearly locked',
      'mind lock'
    ]

    # Array of balance descriptions indicating character's current balance state
    # from worst ('completely') to best ('incredibly')
    #
    # @return [Array<String>] Array of balance state descriptions
    DR_BALANCE_VALUES = [
      'completely',
      'hopelessly',
      'extremely',
      'very badly',
      'badly',
      'somewhat off',
      'off',
      'slightly off',
      'solidly',
      'nimbly',
      'adeptly',
      'incredibly'
    ]

    # Nested hash containing skill categorization and guild-specific skill aliases
    #
    # @return [Hash] Hash with :skillsets and :guild_skill_aliases keys
    DR_SKILLS_DATA = {
      "skillsets": {
        "Armor": [
          "Shield Usage",
          "Light Armor",
          "Chain Armor",
          "Brigandine",
          "Plate Armor",
          "Defending",
          "Conviction"
        ],
        "Lore": [
          "Alchemy",
          "Appraisal",
          "Enchanting",
          "Engineering",
          "Forging",
          "Outfitting",
          "Performance",
          "Scholarship",
          "Tactics",
          "Empathy",
          "Bardic Lore",
          "Trading",
          "Mechanical Lore"
        ],
        "Weapon": [
          "Parry Ability",
          "Small Edged",
          "Large Edged",
          "Twohanded Edged",
          "Small Blunt",
          "Large Blunt",
          "Twohanded Blunt",
          "Slings",
          "Bow",
          "Crossbow",
          "Staves",
          "Polearms",
          "Light Thrown",
          "Heavy Thrown",
          "Brawling",
          "Offhand Weapon",
          "Melee Mastery",
          "Missile Mastery",
          "Expertise"
        ],
        "Magic": [
          "Primary Magic",
          "Arcana",
          "Attunement",
          "Augmentation",
          "Debilitation",
          "Targeted Magic",
          "Utility",
          "Warding",
          "Sorcery",
          "Astrology",
          "Summoning",
          "Theurgy",
          "Inner Magic",
          "Inner Fire",
          "Lunar Magic",
          "Elemental Magic",
          "Holy Magic",
          "Life Magic",
          "Arcane Magic"
        ],
        "Survival": [
          "Evasion",
          "Athletics",
          "Perception",
          "Stealth",
          "Locksmithing",
          "Thievery",
          "First Aid",
          "Outdoorsmanship",
          "Skinning",
          "Instinct",
          "Backstab",
          "Thanatology"
        ]
      },
      "guild_skill_aliases": {
        "Cleric": {
          "Primary Magic": "Holy Magic"
        },
        "Necromancer": {
          "Primary Magic": "Arcane Magic"
        },
        "Warrior Mage": {
          "Primary Magic": "Elemental Magic"
        },
        "Thief": {
          "Primary Magic": "Inner Magic"
        },
        "Barbarian": {
          "Primary Magic": "Inner Fire"
        },
        "Ranger": {
          "Primary Magic": "Life Magic"
        },
        "Bard": {
          "Primary Magic": "Elemental Magic"
        },
        "Paladin": {
          "Primary Magic": "Holy Magic"
        },
        "Empath": {
          "Primary Magic": "Life Magic"
        },
        "Trader": {
          "Primary Magic": "Lunar Magic"
        },
        "Moon Mage": {
          "Primary Magic": "Lunar Magic"
        }
      }
    }

    # List of banks that accept Kronars currency
    #
    # @return [Array<String>] Array of bank location names
    KRONAR_BANKS = ['Crossings', 'Dirge', 'Ilaya Taipa', 'Leth Deriel']

    # List of banks that accept Lirums currency
    #
    # @return [Array<String>] Array of bank location names
    LIRUM_BANKS = ["Aesry Surlaenis'a", "Hara'jaal", "Mer'Kresh", "Muspar'i", "Ratha", "Riverhaven", "Rossman's Landing", "Therenborough", "Throne City"]

    # List of banks that accept Dokoras currency
    #
    # @return [Array<String>] Array of bank location names
    DOKORA_BANKS = ["Ain Ghazal", "Boar Clan", "Chyolvea Tayeu'a", "Hibarnhvidar", "Fang Cove", "Raven's Point", "Shard"]

    # Mapping of bank locations to their in-game room titles
    #
    # @return [Hash{String => Array<String>}] Hash mapping locations to room title arrays
    BANK_TITLES = {
      "Aesry Surlaenis'a" => ["[[Tona Kertigen, Deposit Window]]"],
      "Ain Ghazal"        => ["[[Ain Ghazal, Private Depository]]"],
      "Boar Clan"         => ["[[Ranger Guild, Bank]]"],
      "Chyolvea Tayeu'a"  => ["[[Chyolvea Tayeu'a, Teller]]"],
      "Crossings"         => ["[[Provincial Bank, Teller]]"],
      "Dirge"             => ["[[Dirge, Traveller's Bank]]"],
      "Fang Cove"         => ["[[First Council Banking, Vault]]"],
      "Hara'jaal"         => ["[[Baron's Forset, Teller]]"],
      "Hibarnhvidar"      => ["[[Second Provincial Bank of Hibarnhvidar, Teller]]", "[[Hibarnhvidar, Teller Windows]]", "[[First Arachnid Bank, Lobby]]"],
      "Ilaya Taipa"       => ["[[Ilaya Taipa, Trader Outpost Bank]]"],
      "Leth Deriel"       => ["[[Imperial Depository, Domestic Branch]]"],
      "Mer'Kresh"         => ["[[Harti Clemois Bank, Teller's Window]]"],
      "Muspar'i"          => ["[[Old Lata'arna Keep, Teller Windows]]"],
      "Ratha"             => ["[[Lower Bank of Ratha, Cashier]]", "[[Sshoi-sson Palace, Grand Provincial Bank, Bursarium]]"],
      "Raven's Point"     => ["[[Bank of Raven's Point, Depository]]"],
      "Riverhaven"        => ["[[Bank of Riverhaven, Teller]]"],
      "Rossman's Landing" => ["[[Traders' Guild Outpost, Depository]]"],
      "Shard"             => ["[[First Bank of Ilithi, Teller's Windows]]"],
      "Therenborough"     => ["[[Bank of Therenborough, Teller]]"],
      "Throne City"       => ["[[Faldesu Exchequer, Teller]]"]
    }

    # Mapping of vault locations to their in-game room titles
    #
    # @return [Hash{String => Array<String>}] Hash mapping locations to room title arrays
    VAULT_TITLES = {
      "Crossings"     => ["[[Crossing, Carousel Chamber]]"],
      "Fang Cove"     => ["[[Fang Cove, Carousel Chamber]]"],
      "Leth Deriel"   => ["[[Leth Deriel, Carousel Chamber]]"],
      "Mer'Kresh"     => ["[[Mer'Kresh, Carousel Square]]"],
      "Muspar'i"      => ["[[Muspar'i, Carousel Square]]"],
      "Ratha"         => ["[[Ratha, Carousel Square]]"],
      "Riverhaven"    => ["[[Riverhaven, Carousel Chamber]]"],
      "Shard"         => ["[[Shard, Carousel Chamber]]"],
      "Therenborough" => ["[[Therenborough, Carousel Chamber]]"]
    }

    # Default duration value used for spells/abilities with unknown duration
    #
    # @return [Integer] Duration in seconds (1000)
    UNKNOWN_DURATION = 1000 unless defined?(UNKNOWN_DURATION)

    # Hash mapping canonical town names to their matching regular expressions
    #
    # @return [Hash{String => Regexp}] Town name regex mapping
    $HOMETOWN_REGEX_MAP = {
      "Arthe Dale"        => /^(arthe( dale)?)$/i,
      "Crossing"          => /^(cross(ing)?)$/i,
      "Darkling Wood"     => /^(darkling( wood)?)$/i,
      "Dirge"             => /^(dirge)$/i,
      "Fayrin's Rest"     => /^(fayrin'?s?( rest)?)$/i,
      "Leth Deriel"       => /^(leth( deriel)?)$/i,
      "Shard"             => /^(shard)$/i,
      "Steelclaw Clan"    => /^(steel( )?claw( clan)?|SCC)$/i,
      "Stone Clan"        => /^(stone( clan)?)$/i,
      "Tiger Clan"        => /^(tiger( clan)?)$/i,
      "Wolf Clan"         => /^(wolf( clan)?)$/i,
      "Riverhaven"        => /^(river|haven|riverhaven)$/i,
      "Rossman's Landing" => /^(rossman'?s?( landing)?)$/i,
      "Therenborough"     => /^(theren(borough)?)$/i,
      "Langenfirth"       => /^(lang(enfirth)?)$/i,
      "Fornsted"          => /^(fornsted)$/i,
      "Hvaral"            => /^(hvaral)$/i,
      "Ratha"             => /^(ratha)$/i,
      "Aesry"             => /^(aesry)$/i,
      "Mer'Kresh"         => /^(mer'?kresh)$/i,
      "Throne City"       => /^(throne( city)?)$/i,
      "Hibarnhvidar"      => /^(hib(arnhvidar)?)$/i,
      "Raven's Point"     => /^(raven'?s?( point)?)$/i,
      "Boar Clan"         => /^(boar( clan)?)$/i,
      "Fang Cove"         => /^(fang( cove)?)$/i,
      "Muspar'i"          => /^(muspar'?i)$/i,
      "Ain Ghazal"        => /^(ain( )?ghazal)$/i
    }

    # Array of canonical town names
    #
    # @return [Array<String>] List of official town names
    $HOMETOWN_LIST = $HOMETOWN_REGEX_MAP.keys

    # Combined regular expression matching any valid town name
    #
    # @return [Regexp] Town name matching regex
    $HOMETOWN_REGEX = Regexp.union($HOMETOWN_REGEX_MAP.values)

    # Array of ordinal number words from "first" to "twentieth"
    #
    # @return [Array<String>] List of ordinal numbers as words
    $ORDINALS = %w[first second third fourth fifth sixth seventh eighth ninth tenth eleventh twelfth thirteenth fourteenth fifteenth sixteenth seventeenth eighteenth nineteenth twentieth]

    # Array of currency names
    #
    # @return [Array<String>] List of currency types
    $CURRENCIES = %w[Kronars Lirums Dokoras]

    # Hash mapping encumbrance descriptions to numeric values (0-11)
    #
    # @return [Hash{String => Integer}] Encumbrance level mapping
    $ENC_MAP = {
      'None'                                => 0,
      'Light Burden'                        => 1,
      'Somewhat Burdened'                   => 2,
      'Burdened'                           => 3,
      'Heavy Burden'                        => 4,
      'Very Heavy Burden'                   => 5,
      'Overburdened'                        => 6,
      'Very Overburdened'                   => 7,
      'Extremely Overburdened'              => 8,
      'Tottering Under Burden'              => 9,
      'Are you even able to move?'          => 10,
      'It\'s amazing you aren\'t squashed!' => 11
    }

    # Hash mapping number words to their numeric values
    #
    # @return [Hash{String => Integer}] Number word to integer mapping
    $NUM_MAP = {
      'zero'      => 0,
      'one'       => 1,
      'two'       => 2,
      'three'     => 3,
      'four'      => 4,
      'five'      => 5,
      'six'       => 6,
      'seven'     => 7,
      'eight'     => 8,
      'nine'      => 9,
      'ten'       => 10,
      'eleven'    => 11,
      'twelve'    => 12,
      'thirteen'  => 13,
      'fourteen'  => 14,
      'fifteen'   => 15,
      'sixteen'   => 16,
      'seventeen' => 17,
      'eighteen'  => 18,
      'nineteen'  => 19,
      'twenty'    => 20,
      'thirty'    => 30,
      'forty'     => 40,
      'fifty'     => 50,
      'sixty'     => 60,
      'seventy'   => 70,
      'eighty'    => 80,
      'ninety'    => 90
    }

    # Regular expression matching storage container descriptions
    #
    # @return [Regexp] Container matching pattern
    $box_regex = /((?:brass|copper|deobar|driftwood|iron|ironwood|mahogany|oaken|pine|steel|wooden) (?:box|caddy|casket|chest|coffer|crate|skippet|strongbox|trunk))/

    # Hash mapping mana strength categories to arrays of descriptive terms
    #
    # @return [Hash{String => Array<String>}] Mana level descriptions
    $MANA_MAP = {
      'weak'       => %w[dim glowing bright],
      'developing' => %w[faint muted glowing luminous bright],
      'improving'  => %w[faint hazy flickering shimmering glowing lambent shining fulgent glaring],
      'good'       => %w[faint dim hazy dull muted dusky pale flickering shimmering pulsating glowing lambent shining luminous radiant fulgent brilliant flaring glaring blazing blinding]
    }

    # Regular expression matching primary magic sigil names
    #
    # @return [Regexp] Primary sigil matching pattern
    $PRIMARY_SIGILS_PATTERN = /\b(?:abolition|congruence|induction|permutation|rarefaction) sigil\b/

    # Regular expression matching secondary magic sigil names
    #
    # @return [Regexp] Secondary sigil matching pattern
    $SECONDARY_SIGILS_PATTERN = /\b(?:antipode|ascension|clarification|decay|evolution|integration|metamorphosis|nurture|paradox|unity) sigil\b/

    # Hash mapping volume descriptors to numeric values
    #
    # @return [Hash{String => Integer}] Volume size mapping
    $VOL_MAP = {
      'enormous' => 20,
      'massive'  => 10,
      'huge'     => 5,
      'large'    => 4,
      'medium'   => 3,
      'small'    => 2,
      'tiny'     => 1
    }
  end
end