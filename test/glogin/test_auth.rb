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

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/glogin/cookie'

class TestAuth < Minitest::Test
  def test_authenticate_via_https
    auth = GLogin::Auth.new('1234', '4433', 'https://example.org')
    stub_request(:post, 'https://github.com/login/oauth/access_token').to_return(
      body: {
        access_token: 'some-token'
      }.to_json
    )
    stub_request(:get, 'https://api.github.com/user').to_return(
      body: {
        auth_code: '437849732894732',
        login: 'yegor256'
      }.to_json
    )
    user = auth.user('437849732894732')
    assert_equal('yegor256', user['login'])
  end

  def test_login_uri
    auth = GLogin::Auth.new(
      'client_id', 'client_secret', 'http://www.example.com/github-oauth'
    )
    assert(
      auth.login_uri.start_with?(
        'https://github.com/login/oauth/authorize'
      )
    )
  end

  def test_get_fake_user
    auth = GLogin::Auth.new('99999', '', 'http://www.example.com/github-oauth')
    assert_equal('yegor256', auth.user('1234567890')['login'])
  end

  def test_failed_authentication
    auth = GLogin::Auth.new('1234', '4433', 'https://example.org')
    stub_request(:post, 'https://github.com/login/oauth/access_token').to_return(status: 401)
    e = assert_raises { auth.user('437849732894732') }
    assert(e.message.include?('with code "43784***'))
  end
end
