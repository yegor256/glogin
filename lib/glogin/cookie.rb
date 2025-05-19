# frozen_string_literal: true

#
# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'openssl'
require 'digest/sha1'
require 'base64'
require_relative 'codec'

# GLogin main module.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
module GLogin
  # Split symbol inside the cookie text
  SPLIT = '|'

  # Secure cookie management for user sessions.
  #
  # This class provides two nested classes for handling cookies:
  # - Cookie::Open: Creates encrypted cookies from user data
  # - Cookie::Closed: Decrypts and validates existing cookies
  #
  # The cookie format stores user ID, login, avatar URL, and an optional
  # context string for additional security validation.
  #
  # @example Creating and reading a cookie
  #   # After successful authentication
  #   user_data = auth.user(code)
  #   cookie = GLogin::Cookie::Open.new(user_data, 'secret-key')
  #   response.set_cookie('glogin', cookie.to_s)
  #   
  #   # When reading the cookie
  #   cookie_text = request.cookies['glogin']
  #   closed = GLogin::Cookie::Closed.new(cookie_text, 'secret-key')
  #   user = closed.to_user
  #   # => {"id"=>"123", "login"=>"username", "avatar_url"=>"https://..."}
  class Cookie
    # Closed cookie for reading existing cookies.
    #
    # An instance of this class is created when a cookie arrives
    # from the client. The encrypted cookie text is decrypted to
    # retrieve the original user information.
    #
    # @example Read a cookie from HTTP request
    #   cookie_text = request.cookies['glogin']
    #   closed = GLogin::Cookie::Closed.new(cookie_text, ENV['SECRET'])
    #   
    #   begin
    #     user = closed.to_user
    #     session[:user_id] = user['id']
    #   rescue GLogin::Codec::DecodingError
    #     # Invalid cookie - redirect to login
    #     redirect '/login'
    #   end
    #
    # @example Using context for additional security
    #   closed = GLogin::Cookie::Closed.new(
    #     cookie_text,
    #     ENV['SECRET'],
    #     request.ip  # Validate against IP address
    #   )
    #   user = closed.to_user
    class Closed
      # Creates a new closed cookie instance.
      #
      # @param text [String] The encrypted cookie text to decrypt
      # @param secret [String] The secret key used for decryption
      # @param context [String] Optional context string for validation
      # @raise [RuntimeError] if any parameter is nil
      def initialize(text, secret, context = '')
        raise 'Text can\'t be nil' if text.nil?
        @text = text
        raise 'Secret can\'t be nil' if secret.nil?
        @secret = secret
        raise 'Context can\'t be nil' if context.nil?
        @context = context.to_s
      end

      # Decrypts and returns the user information from the cookie.
      #
      # @return [Hash] User information with keys 'id', 'login', and 'avatar_url'
      # @raise [GLogin::Codec::DecodingError] if:
      #   - The cookie is corrupted or tampered with
      #   - The wrong secret key is used
      #   - The context doesn't match (if provided)
      # @example Basic usage
      #   user = closed.to_user
      #   # => {"id"=>"123", "login"=>"octocat", "avatar_url"=>"https://..."}
      #
      # @example Error handling
      #   begin
      #     user = closed.to_user
      #     puts "Welcome, #{user['login']}!"
      #   rescue GLogin::Codec::DecodingError => e
      #     puts "Invalid session: #{e.message}"
      #     redirect_to_login
      #   end
      #
      # @note If the secret is empty (test mode), the text is used as-is without decryption
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

    # Open cookie for creating new cookies.
    #
    # This class takes user information from GitHub authentication
    # and creates an encrypted cookie that can be sent to the client.
    #
    # @example Create a cookie after successful authentication
    #   user_data = auth.user(code)
    #   open = GLogin::Cookie::Open.new(user_data, ENV['SECRET'])
    #   
    #   # Set cookie with options
    #   response.set_cookie('glogin', {
    #     value: open.to_s,
    #     expires: 1.week.from_now,
    #     httponly: true,
    #     secure: true
    #   })
    #
    # @example Using context for IP-based validation
    #   open = GLogin::Cookie::Open.new(
    #     user_data,
    #     ENV['SECRET'],
    #     request.ip  # Bind cookie to IP address
    #   )
    #   response.set_cookie('glogin', open.to_s)
    class Open
      attr_reader :id, :login, :avatar_url

      # Creates a new open cookie from user data.
      #
      # @param json [Hash] User data from Auth#user, must contain 'id' key
      # @param secret [String] Secret key for encryption
      # @param context [String] Optional context for additional validation
      # @raise [RuntimeError] if json is nil or missing 'id' key
      # @raise [RuntimeError] if secret or context is nil
      # @example
      #   user_data = {
      #     'id' => '123456',
      #     'login' => 'octocat',
      #     'avatar_url' => 'https://github.com/octocat.png'
      #   }
      #   open = GLogin::Cookie::Open.new(user_data, 'secret-key')
      #   puts open.id         # => "123456"
      #   puts open.login      # => "octocat"
      #   puts open.avatar_url # => "https://github.com/octocat.png"
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

      # Generates the encrypted cookie string.
      #
      # This method encrypts the user information (id, login, avatar_url, and context)
      # into a string that can be sent as an HTTP cookie. The encryption ensures
      # the cookie cannot be tampered with.
      #
      # @return [String] The encrypted cookie value
      # @example Generate cookie for HTTP response
      #   open = GLogin::Cookie::Open.new(user_data, secret)
      #   cookie_value = open.to_s
      #   # => "3Hs9k2LgU..." (encrypted string)
      #   
      #   # Use with Sinatra
      #   response.set_cookie('glogin', cookie_value)
      #   
      #   # Use with Rails
      #   cookies[:glogin] = {
      #     value: cookie_value,
      #     expires: 1.week.from_now,
      #     httponly: true
      #   }
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
