# frozen_string_literal: true

#
# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'net/http'
require 'uri'
require 'json'
require 'cgi'

# GLogin main module.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
module GLogin
  # GitHub authentication mechanism.
  #
  # This class handles the OAuth flow with GitHub, including generating
  # authorization URLs and exchanging authorization codes for access tokens
  # to retrieve user information.
  #
  # @example Creating an Auth instance
  #   auth = GLogin::Auth.new(
  #     'your-github-client-id',
  #     'your-github-client-secret',
  #     'https://yourapp.com/callback'
  #   )
  #
  # @example Getting the GitHub login URL
  #   login_url = auth.login_uri
  #   # => "https://github.com/login/oauth/authorize?client_id=...&redirect_uri=..."
  #
  # @example Retrieving user information after callback
  #   user_info = auth.user(params[:code])
  #   # => {"id"=>"123456", "login"=>"username", "avatar_url"=>"https://..."}
  class Auth
    # Creates a new GitHub authentication handler.
    #
    # @param id [String] GitHub OAuth application client ID
    # @param secret [String] GitHub OAuth application client secret
    # @param redirect [String] The callback URL where GitHub will redirect after authentication
    # @raise [RuntimeError] if any parameter is nil or redirect is empty
    # @example
    #   auth = GLogin::Auth.new(
    #     ENV['GITHUB_CLIENT_ID'],
    #     ENV['GITHUB_CLIENT_SECRET'],
    #     'https://myapp.com/auth/callback'
    #   )
    def initialize(id, secret, redirect)
      raise "GitHub client ID can't be nil" if id.nil?
      @id = id
      raise "GitHub client secret can't be nil" if secret.nil?
      @secret = secret
      raise "Redirect URL can't be nil" if redirect.nil?
      raise "Redirect URL can't be empty" if redirect.empty?
      @redirect = redirect
    end

    # Generates the GitHub OAuth authorization URL.
    #
    # Users should be redirected to this URL to begin the authentication process.
    # GitHub will ask them to authorize your application, then redirect them back
    # to your specified redirect URL with an authorization code.
    #
    # @return [String] The GitHub OAuth authorization URL
    # @example Redirect users to GitHub for authentication
    #   auth = GLogin::Auth.new(id, secret, redirect_url)
    #   redirect auth.login_uri
    def login_uri
      "https://github.com/login/oauth/authorize?client_id=#{CGI.escape(@id)}&redirect_uri=#{CGI.escape(@redirect)}"
    end

    # Returns a hash with information about GitHub user
    # who just logged in with the authentication code.
    #
    # This method exchanges the temporary authorization code (received from GitHub
    # callback) for an access token, then uses that token to fetch the user's
    # profile information.
    #
    # @param code [String] The authorization code received from GitHub callback
    # @return [Hash] User information including 'id', 'login', and 'avatar_url'
    # @raise [RuntimeError] if the code is nil, empty, or if the API request fails
    # @example Handling the GitHub callback
    #   get '/auth/callback' do
    #     code = params[:code]
    #     user = auth.user(code)
    #     # user => {"id"=>"123456", "login"=>"octocat", "avatar_url"=>"https://..."}
    #     session[:user_id] = user['id']
    #   end
    # @note When secret is empty (test mode), returns a mock user object
    # @see https://docs.github.com/en/rest/users/users?apiVersion=2022-11-28#get-the-authenticated-user
    def user(code)
      if @secret.empty?
        return {
          'id' => 526_301,
          'login' => 'yegor256',
          'avatar_url' => 'https://github.com/yegor256.png'
        }
      end
      raise 'Code can\'t be nil' if code.nil?
      raise 'Code can\'t be empty' if code.empty?
      uri = URI.parse('https://api.github.com/user')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Get.new(uri.request_uri)
      req['Accept-Header'] = 'application/json'
      token = access_token(code)
      req['Authorization'] = "token #{token}"
      res = http.request(req)
      raise "HTTP error ##{res.code} with token #{escape(token)}: #{res.body}" unless res.code == '200'
      JSON.parse(res.body)
    end

    private

    def access_token(code)
      raise 'Code can\'t be nil' if code.nil?
      raise 'Code can\'t be empty' if code.empty?
      uri = URI.parse('https://github.com/login/oauth/access_token')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Post.new(uri.request_uri)
      req.set_form_data(
        'code' => code,
        'client_id' => @id,
        'client_secret' => @secret
      )
      req['Accept'] = 'application/json'
      res = http.request(req)
      raise "HTTP error ##{res.code} with code #{escape(code)}: #{res.body}" unless res.code == '200'
      json = JSON.parse(res.body)
      token = json['access_token']
      raise "There is no 'access_token' in JSON response from GitHub: #{res.body}" if token.nil?
      token
    end

    def escape(txt)
      prefix = 4
      [
        '"',
        txt[0..prefix],
        '*' * (txt.length - prefix),
        '"'
      ].join
    end
  end
end
