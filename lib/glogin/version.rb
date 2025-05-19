# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# GLogin main module.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
module GLogin
  # Current version of the GLogin gem.
  #
  # @example Check the gem version
  #   puts GLogin::VERSION
  #   # => "0.0.0"
  #
  # @example Version comparison
  #   if Gem::Version.new(GLogin::VERSION) >= Gem::Version.new('0.1.0')
  #     puts "Using GLogin version 0.1.0 or newer"
  #   end
  VERSION = '0.0.0'
end
