# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/glogin/cookie'
require_relative '../test__helper'

class TestCookie < Minitest::Test
  def test_encrypts_and_decrypts
    secret = 'this&84-- (832=_'
    user = GLogin::Cookie::Closed.new(
      GLogin::Cookie::Open.new(
        JSON.parse(
          "{\"id\":123,\"node_id\":\"how are you?\",
          \"login\":\"yegor256\",
          \"avatar_url\":\"https://avatars1.githubusercontent.com/u/526301\"}"
        ),
        secret
      ).to_s,
      secret
    ).to_user
    assert_equal('yegor256', user['login'])
    assert_equal('https://avatars1.githubusercontent.com/u/526301', user['avatar_url'])
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
    assert_equal('123', user['id'])
    assert_equal('jeffrey', user['login'])
    assert_equal('#', user['avatar_url'])
  end

  def test_decrypts_in_test_mode
    user = GLogin::Cookie::Closed.new(
      '123|test|http://example.com', ''
    ).to_user
    assert_equal('123', user['id'])
    assert_equal('test', user['login'])
    assert_equal('http://example.com', user['avatar_url'])
  end

  def test_decrypts_in_test_mode_with_context
    user = GLogin::Cookie::Closed.new(
      '123', '', 'some context'
    ).to_user
    assert_equal('123', user['id'])
    assert_nil(user['login'])
    assert_nil(user['avatar_url'])
  end

  def test_fails_on_broken_text
    assert_raises GLogin::Codec::DecodingError do
      GLogin::Cookie::Closed.new(
        GLogin::Cookie::Open.new(
          JSON.parse('{"login":"x","avatar_url":"x","id":"1"}'),
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
          JSON.parse('{"login":"x","avatar_url":"x","id":""}'),
          secret,
          'context-1'
        ).to_s,
        secret,
        'context-2'
      ).to_user
    end
  end
end
