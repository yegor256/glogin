# frozen_string_literal: true

#
# Copyright (c) 2017-2024 Yegor Bugayenko
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
require_relative 'codec'

# GLogin main module.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2024 Yegor Bugayenko
# License:: MIT
module GLogin
  # Split symbol inside the cookie text
  SPLIT = '|'

  #
  # Secure cookie
  #
  class Cookie
    # Closed cookie.
    #
    # An instance of this class is created when a cookie arrives
    # to the application. The cookie text is provided to the class
    # as the first parameter. Then, when an instance of the class
    # is created, the value encypted inside the cookie text may
    # be retrieved through the +to_user+ method.
    class Closed
      def initialize(text, secret, context = '')
        raise 'Text can\'t be nil' if text.nil?
        @text = text
        raise 'Secret can\'t be nil' if secret.nil?
        @secret = secret
        raise 'Context can\'t be nil' if context.nil?
        @context = context.to_s
      end

      # Returns a hash with four elements: `id`, `login`, and `avatar_url`.
      #
      # If the `secret` is empty, the text will not be decrypted, but used
      # "as is". This may be helpful during testing.
      #
      # If the data is not valid, an exception
      # `GLogin::Codec::DecodingError` will be raised, which you have
      # to catch in your applicaiton and ignore the login attempt.
      def to_user
        plain = Codec.new(@secret).decrypt(@text)
        id, login, avatar_url, ctx = plain.split(GLogin::SPLIT, 5)
        if !@secret.empty? && ctx.to_s != @context
          raise(
            GLogin::Codec::DecodingError,
            "Context '#{@context}' expected, but '#{ctx}' found"
          )
        end
        { 'id' => id, 'login' => login, 'avatar_url' => avatar_url }
      end
    end

    # Open
    class Open
      attr_reader :id, :login, :avatar_url

      # Here comes the JSON you receive from Auth.user().
      #
      # The JSON is a Hash where every key is a string. When the class is instantiated,
      # its methods `id`, `login`, and `avatar_url` may be used to retrieve
      # the data inside the JSON, but this is not what this class is mainly about.
      #
      # The method +to_s+ returns an encrypted cookie string, that may be
      # sent to the user as a +Set-Cookie+ HTTP header.
      def initialize(json, secret, context = '')
        raise 'JSON can\'t be nil' if json.nil?
        raise 'JSON must contain "id" key' if json['id'].nil?
        @id = json['id'].to_s
        @login = (json['login'] || '').to_s
        @avatar_url = (json['avatar_url'] || '').to_s
        @bearer = (json['bearer'] || '').to_s
        raise 'Secret can\'t be nil' if secret.nil?
        @secret = secret
        raise 'Context can\'t be nil' if context.nil?
        @context = context.to_s
      end

      # Returns the text you should drop back to the user as a cookie.
      def to_s
        Codec.new(@secret).encrypt(
          [
            @id,
            @login,
            @avatar_url,
            @context
          ].join(GLogin::SPLIT)
        )
      end
    end
  end
end
