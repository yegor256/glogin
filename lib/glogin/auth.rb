# frozen_string_literal: true

#
# Copyright (c) 2017-2019 Yegor Bugayenko
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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'net/http'
require 'uri'
require 'json'
require 'cgi'

# GLogin main module.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2019 Yegor Bugayenko
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
      @redirect = redirect
    end

    def login_uri
      'https://github.com/login/oauth/authorize?client_id=' +
        CGI.escape(@id) +
        '&redirect_uri=' +
        CGI.escape(@redirect)
    end

    def user(code)
      raise 'Code can\'t be nil' if code.nil?
      uri = URI.parse('https://api.github.com/user')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Get.new(uri.request_uri)
      req['Accept-Header'] = 'application/json'
      req['Authorization'] = "token #{access_token(code)}"
      res = http.request(req)
      raise "Error (#{res.code}): #{res.body}" unless res.code == '200'
      JSON.parse(res.body)
    end

    private

    def access_token(code)
      raise 'Code can\'t be nil' if code.nil?
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
      raise "Error (#{res.code}): #{res.body}" unless res.code == '200'
      JSON.parse(res.body)['access_token']
    end
  end
end
