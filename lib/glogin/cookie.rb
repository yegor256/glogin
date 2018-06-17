#
# Copyright (c) 2017-2018 Yegor Bugayenko
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

require 'openssl'
require 'digest/sha1'
require 'base64'

# GLogin main module.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2018 Yegor Bugayenko
# License:: MIT
module GLogin
  #
  # Secure cookie
  #
  class Cookie
    # Closed cookie.
    class Closed
      def initialize(text, secret, context = '')
        raise 'Text can\'t be nil' if text.nil?
        @text = text
        raise 'Secret can\'t be nil' if secret.nil?
        @secret = secret
        @context = context.to_s
      end

      # Returns a hash with two elements: login and avatar.
      # If the secret is empty, the text will be returned, without
      # any decryption. If the data is not valid, an exception
      # OpenSSL::Cipher::CipherError will be raised, which you have
      # to catch in your applicaiton and ignore the login attempt.
      def to_user
        plain =
          if @secret.empty?
            @text
          else
            cpr = Cookie.cipher
            cpr.decrypt
            cpr.key = Cookie.digest(@secret)
            decrypted = cpr.update(Base64.decode64(@text))
            decrypted << cpr.final
            decrypted.to_s
          end
        parts = plain.split('|', 3)
        unless parts[2].to_s == @context
          raise(
            OpenSSL::Cipher::CipherError,
            "Context '#{@context}' expectected, but '#{parts[2]}' found"
          )
        end
        { login: parts[0], avatar: parts[1] }
      end
    end

    # Open
    class Open
      # Here comes the JSON you receive from Auth.user()
      def initialize(json, secret, context = '')
        raise 'JSON can\'t be nil' if json.nil?
        @json = json
        raise 'Secret can\'t be nil' if secret.nil?
        @secret = secret
        @context = context.to_s
      end

      # Returns the text you should drop back to the user as a cookie.
      def to_s
        cpr = Cookie.cipher
        cpr.encrypt
        cpr.key = Cookie.digest(@secret)
        encrypted = cpr.update(
          "#{@json['login']}|#{@json['avatar_url']}|#{@context}"
        )
        encrypted << cpr.final
        Base64.encode64(encrypted.to_s)
      end
    end

    def self.digest(secret)
      Digest::SHA1.hexdigest(secret)[0..31]
    end

    def self.cipher
      OpenSSL::Cipher.new('aes-256-cbc')
    end
  end
end
