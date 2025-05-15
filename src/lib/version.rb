# Defines version and Ruby compatibility constants for the Lich5 project.
# This module handles semantic versioning and Ruby version requirements.
#
# @author Lich5 Documentation Generator

# Current version of Lich5 following semantic versioning format.
# Format: MAJOR.MINOR.PATCH[-PRERELEASE]
#
# @return [String] The current version string
# @example
#   LICH_VERSION # => "5.12.0-beta.2"
#
# @note This is a beta release version
LICH_VERSION = '5.12.0-beta.2'

# Minimum required Ruby version to run Lich5
#
# @return [String] The minimum supported Ruby version
# @example
#   REQUIRED_RUBY # => "2.6"
#
# @note Applications using Lich5 must use Ruby 2.6 or higher
REQUIRED_RUBY = '2.6'

# Recommended Ruby version for optimal performance
#
# @return [String] The recommended Ruby version
# @example
#   RECOMMENDED_RUBY # => "3.2"
#
# @note While Lich5 will work with older supported versions,
#   version 3.2 is recommended for best performance and feature support
RECOMMENDED_RUBY = '3.2'