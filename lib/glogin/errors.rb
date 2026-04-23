# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# GLogin main module.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2026 Yegor Bugayenko
# License:: MIT
module GLogin
  # Base class for all GLogin-specific errors.
  #
  # @example Rescuing any GLogin error
  #   begin
  #     auth.user(code)
  #   rescue GLogin::Error => e
  #     logger.error("GLogin failed: #{e.message}")
  #   end
  class Error < StandardError
  end

  # Raised when GLogin cannot reach GitHub due to a low-level networking
  # issue (DNS resolution failure, connection refused, TLS handshake
  # failure, read timeout, etc.).
  #
  # The original exception is preserved via Ruby's exception chaining
  # mechanism and is accessible through +#cause+.
  #
  # @example Handling a connection failure gracefully
  #   begin
  #     auth.user(code)
  #   rescue GLogin::ConnectionError => e
  #     logger.warn("GitHub unreachable: #{e.message} (cause: #{e.cause.class})")
  #     halt(503, 'GitHub is unreachable, please try again later')
  #   end
  class ConnectionError < Error
  end
end
