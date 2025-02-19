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
  #
  # GitHub auth mechanism
  #
  class Auth
    def initialize(id, secret, redirect)
      raise "GitHub client ID can't be nil" if id.nil?
      @id = id
      raise "GitHub client secret can't be nil" if secret.nil?
      @secret = secret
      raise "Redirect URL can't be nil" if redirect.nil?
      raise "Redirect URL can't be empty" if redirect.empty?
      @redirect = redirect
    end

    def login_uri
      "https://github.com/login/oauth/authorize?client_id=#{CGI.escape(@id)}&redirect_uri=#{CGI.escape(@redirect)}"
    end

    # Returns a hash with information about Github user,
    # who just logged in with the authentication code.
    #
    # API: https://docs.github.com/en/rest/users/users?apiVersion=2022-11-28#get-the-authenticated-user
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
