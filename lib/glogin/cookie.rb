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
  # Split symbol inside the cookie text
  SPLIT = '|'.freeze

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
        plain = Codec.new(@secret).decrypt(@text)
        login, avatar, code, ctx = plain.split(GLogin::SPLIT, 4)
        if !@secret.empty? && ctx.to_s != @context
          raise(
            OpenSSL::Cipher::CipherError,
            "Context '#{@context}' expected, but '#{ctx}' found"
          )
        end
        { login: login, avatar: avatar, code: code }
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
        Codec.new(@secret).encrypt(
          [
            @json['login'],
            @json['avatar_url'],
            @json['auth_code'],
            @context
          ].join(GLogin::SPLIT)
        )
      end
    end
  end
end
