# Main commons loader for Lich5 that imports all common functionality modules.
# This file serves as the central point for loading shared utilities and features
# used throughout the Lich5 system.
#
# Loads the following common modules:
# - Basic common utilities
# - Validation helpers
# - Item management
# - Equipment management
# - Moon mage specific utilities  
# - Summoning related functions
# - Arcana magic utilities
# - Travel and movement helpers
# - Theurgy religious magic
# - Money and currency handling
# - Healing data constants
# - Healing action helpers
# - Crafting system utilities
# - Slack integration bot
#
# @author Lich5 Documentation Generator
#
# @note This file should be required first before using any common functionality
#
# @example Loading all commons
#   require_relative 'commons'
#
# @see Common
# @see CommonValidation  
# @see CommonItems
# @see EquipManager
# @see CommonMoonmage
# @see CommonSummoning
# @see CommonArcana
# @see CommonTravel
# @see CommonTheurgy
# @see CommonMoney
# @see CommonHealingData
# @see CommonHealing
# @see CommonCrafting
# @see Slackbot

require_relative "./commons/common"
require_relative "./commons/common-validation"
require_relative "./commons/common-items"
require_relative "./commons/equipmanager"
require_relative "./commons/common-moonmage"
require_relative "./commons/common-summoning"
require_relative "./commons/common-arcana"
require_relative "./commons/common-travel"
require_relative "./commons/common-theurgy"
require_relative "./commons/common-money"
require_relative "./commons/common-healing-data"
require_relative "./commons/common-healing"
require_relative "./commons/common-crafting"
require_relative "./commons/slackbot"