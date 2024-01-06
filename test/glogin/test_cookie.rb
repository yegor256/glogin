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
require_relative '../../lib/glogin/cookie'

class TestCookie < Minitest::Test
  def test_encrypts_and_decrypts
    secret = 'this&84-- (832=_'
    user = GLogin::Cookie::Closed.new(
      GLogin::Cookie::Open.new(
        JSON.parse(
          "{\"id\":\"123\",
          \"login\":\"yegor256\",
          \"avatar_url\":\"https://avatars1.githubusercontent.com/u/526301\"}"
        ),
        secret
      ).to_s,
      secret
    ).to_user
    assert_equal(user[:login], 'yegor256')
    assert_equal(user[:avatar], 'https://avatars1.githubusercontent.com/u/526301')
  end

  def test_encrypts_and_decrypts_with_context
    secret = 'kfdj7hjsywhs6hjshr7shsw990s'
    context = '127.0.0.1'
    user = GLogin::Cookie::Closed.new(
      GLogin::Cookie::Open.new(
        JSON.parse('{"id":"123","login":"jeffrey","avatar_url":"#"}'),
        secret,
        context
      ).to_s,
      secret,
      context
    ).to_user
    assert_equal(user[:id], '123')
    assert_equal(user[:login], 'jeffrey')
    assert_equal(user[:avatar], '#')
  end

  def test_decrypts_in_test_mode
    user = GLogin::Cookie::Closed.new(
      '123|test|http://example.com', ''
    ).to_user
    assert_equal(user[:id], '123')
    assert_equal(user[:login], 'test')
    assert_equal(user[:avatar], 'http://example.com')
  end

  def test_decrypts_in_test_mode_with_context
    user = GLogin::Cookie::Closed.new(
      '123', '', 'some context'
    ).to_user
    assert_equal('123', user[:id])
    assert_nil(user[:login])
    assert_nil(user[:avatar])
  end

  def test_fails_on_broken_text
    assert_raises GLogin::Codec::DecodingError do
      GLogin::Cookie::Closed.new(
        GLogin::Cookie::Open.new(
          JSON.parse('{"login":"x","avatar_url":"x"}'),
          'secret-1'
        ).to_s,
        'secret-2'
      ).to_user
    end
  end

  def test_fails_on_wrong_context
    secret = 'fdjruewoijs789fdsufds89f7ds89fs'
    assert_raises GLogin::Codec::DecodingError do
      GLogin::Cookie::Closed.new(
        GLogin::Cookie::Open.new(
          JSON.parse('{"login":"x","avatar_url":"x"}'),
          secret,
          'context-1'
        ).to_s,
        secret,
        'context-2'
      ).to_user
    end
  end
end
