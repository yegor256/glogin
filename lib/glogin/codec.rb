# frozen_string_literal: true

#
# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'
require 'openssl'
require 'digest/sha1'
require 'base58'
require 'base64'

# Codec.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
module GLogin
  # The codec
  class Codec
    # When can't decode.
    class DecodingError < StandardError; end

    # Ctor.
    # +secret+: The secret to do the encoding
    # +base64+: If TRUE, Base-64 will be used, otherwise Base-58
    def initialize(secret = '', base64: false)
      raise 'Secret can\'t be nil' if secret.nil?
      @secret = secret
      @base64 = base64
    end

    def decrypt(text)
      raise 'Text can\'t be nil' if text.nil?
      if @secret.empty?
        text
      else
        cpr = cipher
        cpr.decrypt
        cpr.key = digest(cpr.key_len)
        if @base64
          raise DecodingError, "This is not Base64: #{text.inspect}" unless %r{^[a-zA-Z0-9\\+/=]+$}.match?(text)
        else
          raise DecodingError, "This is not Base58: #{text.inspect}" unless /^[a-km-zA-HJ-NP-Z1-9]+$/.match?(text)
        end
        plain = @base64 ? Base64.decode64(text) : Base58.base58_to_binary(text)
        raise DecodingError if plain.empty?
        decrypted = cpr.update(plain)
        decrypted << cpr.final
        salt, body = decrypted.to_s.split(' ', 2)
        raise DecodingError if salt.empty?
        raise DecodingError if body.nil?
        body.force_encoding('UTF-8')
        body
      end
    rescue OpenSSL::Cipher::CipherError => e
      raise DecodingError, e.message
    end

    def encrypt(text)
      raise 'Text can\'t be nil' if text.nil?
      if @secret.empty?
        text
      else
        cpr = cipher
        cpr.encrypt
        cpr.key = digest(cpr.key_len)
        salt = SecureRandom.base64(Random.rand(8..32))
        encrypted = cpr.update("#{salt} #{text}")
        encrypted << cpr.final
        @base64 ? Base64.encode64(encrypted).delete("\n") : Base58.binary_to_base58(encrypted)
      end
    end

    private

    def digest(len)
      Digest::SHA1.hexdigest(@secret)[0..len - 1]
    end

    def cipher
      OpenSSL::Cipher.new('aes-256-cbc')
    end
  end
end
