# frozen_string_literal: true

#
# Copyright (c) 2017-2023 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'securerandom'
require 'openssl'
require 'digest/sha1'
require 'base58'

# Codec.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2023 Yegor Bugayenko
# License:: MIT
class GLogin::Codec
  # When can't decode.
  class DecodingError < StandardError; end

  def initialize(secret = '')
    raise 'Secret can\'t be nil' if secret.nil?
    @secret = secret
  end

  def decrypt(text)
    raise 'Text can\'t be nil' if text.nil?
    if @secret.empty?
      text
    else
      cpr = cipher
      cpr.decrypt
      cpr.key = digest
      raise DecodingError unless /^[a-zA-Z0-9]+$/.match?(text)
      plain = Base58.base58_to_binary(text)
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
      cpr.key = digest
      salt = SecureRandom.base64(Random.rand(8..32))
      encrypted = cpr.update("#{salt} #{text}")
      encrypted << cpr.final
      Base58.binary_to_base58(encrypted)
    end
  end

  def digest
    Digest::SHA1.hexdigest(@secret)[0..31]
  end

  def cipher
    OpenSSL::Cipher.new('aes-256-cbc')
  end
end
