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
  # The codec for encrypting and decrypting text.
  #
  # This class provides symmetric encryption using AES-256-CBC. It can encode
  # text using either Base64 or Base58 encoding. A random salt is added to
  # each encryption to ensure that the same plaintext produces different
  # ciphertexts each time.
  #
  # @example Basic encryption and decryption
  #   codec = GLogin::Codec.new('my-secret-key')
  #   encrypted = codec.encrypt('sensitive data')
  #   decrypted = codec.decrypt(encrypted)
  #   # => "sensitive data"
  #
  # @example Using Base64 encoding
  #   codec = GLogin::Codec.new('secret', base64: true)
  #   encrypted = codec.encrypt('hello world')
  #   # => "U29tZUJhc2U2NEVuY29kZWRTdHJpbmc="
  #
  # @example Test mode without encryption
  #   codec = GLogin::Codec.new('')  # Empty secret
  #   encrypted = codec.encrypt('plaintext')
  #   # => "plaintext" (no encryption in test mode)
  class Codec
    # Raised when decryption fails.
    #
    # This can happen when:
    # - The encrypted text is corrupted
    # - The wrong secret key is used
    # - The text is not properly encoded (Base64/Base58)
    class DecodingError < StandardError; end

    # Creates a new codec instance.
    #
    # @param secret [String] The secret key for encryption. If empty, no encryption is performed (test mode)
    # @param base64 [Boolean] Whether to use Base64 encoding (true) or Base58 encoding (false)
    # @raise [RuntimeError] if secret is nil
    # @example Create codec with Base58 encoding (default)
    #   codec = GLogin::Codec.new('my-secret-key')
    #
    # @example Create codec with Base64 encoding
    #   codec = GLogin::Codec.new('my-secret-key', base64: true)
    #
    # @example Create codec in test mode (no encryption)
    #   codec = GLogin::Codec.new('')
    def initialize(secret = '', base64: false)
      raise 'Secret can\'t be nil' if secret.nil?
      @secret = secret
      @base64 = base64
    end

    # Decrypts an encrypted text string.
    #
    # @param text [String] The encrypted text to decrypt
    # @return [String] The decrypted plaintext
    # @raise [RuntimeError] if text is nil
    # @raise [DecodingError] if decryption fails due to:
    #   - Invalid Base64/Base58 encoding
    #   - Wrong secret key
    #   - Corrupted ciphertext
    #   - Missing or invalid salt
    # @example Decrypt a Base58-encoded string
    #   codec = GLogin::Codec.new('secret')
    #   plaintext = codec.decrypt('3Hs9k2LgU...')
    #   # => "hello world"
    #
    # @example Handle decryption errors
    #   begin
    #     plaintext = codec.decrypt(corrupted_text)
    #   rescue GLogin::Codec::DecodingError => e
    #     puts "Decryption failed: #{e.message}"
    #   end
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

    # Encrypts a plaintext string.
    #
    # The method adds a random salt to the text before encryption to ensure
    # that encrypting the same text multiple times produces different results.
    # The encrypted output is encoded using either Base64 or Base58.
    #
    # @param text [String] The plaintext to encrypt
    # @return [String] The encrypted and encoded text
    # @raise [RuntimeError] if text is nil
    # @example Encrypt with Base58 encoding
    #   codec = GLogin::Codec.new('secret')
    #   encrypted = codec.encrypt('sensitive data')
    #   # => "3Hs9k2LgU..." (Base58 encoded)
    #
    # @example Encrypt with Base64 encoding  
    #   codec = GLogin::Codec.new('secret', base64: true)
    #   encrypted = codec.encrypt('sensitive data')
    #   # => "U29tZUJhc2U2NC..." (Base64 encoded)
    #
    # @example Multiple encryptions produce different results
    #   codec = GLogin::Codec.new('secret')
    #   enc1 = codec.encrypt('hello')
    #   enc2 = codec.encrypt('hello')
    #   enc1 != enc2  # => true (due to random salt)
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
