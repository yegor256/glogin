# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/glogin/cookie'
require_relative '../test__helper'

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
    assert_equal('torvalds', auth.user('1234567890')['login'])
  end

  def test_failed_authentication
    auth = GLogin::Auth.new('1234', '4433', 'https://example.org')
    stub_request(:post, 'https://github.com/login/oauth/access_token').to_return(status: 401)
    e = assert_raises(StandardError) { auth.user('437849732894732') }
    assert_includes(e.message, 'with code "43784***')
  end

  def test_broken_json
    auth = GLogin::Auth.new('1234', '4433', 'https://example.org')
    stub_request(:post, 'https://github.com/login/oauth/access_token').to_return(body: 'Hello!')
    e = assert_raises(StandardError) { auth.user('47839893') }
    assert_includes(e.message, 'unexpected', e)
  end

  def test_no_token_in_json
    auth = GLogin::Auth.new('1234', '4433', 'https://example.org')
    stub_request(:post, 'https://github.com/login/oauth/access_token').to_return(body: '{}')
    e = assert_raises(StandardError) { auth.user('47839893') }
    assert_includes(e.message, 'There is no \'access_token\'', e)
  end

  def test_wraps_dns_failure_on_token_exchange
    require 'socket'
    auth = GLogin::Auth.new('1234', '4433', 'https://example.org')
    stub_request(:post, 'https://github.com/login/oauth/access_token')
      .to_raise(Socket::ResolutionError.new('getaddrinfo: Name or service not known'))
    e = assert_raises(GLogin::ConnectionError) { auth.user('437849732894732') }
    assert_kind_of(GLogin::Error, e)
    assert_kind_of(Socket::ResolutionError, e.cause)
  end

  def test_wraps_connection_refused_on_user_fetch
    auth = GLogin::Auth.new('1234', '4433', 'https://example.org')
    stub_request(:post, 'https://github.com/login/oauth/access_token').to_return(
      body: { access_token: 'some-token' }.to_json
    )
    stub_request(:get, 'https://api.github.com/user')
      .to_raise(Errno::ECONNREFUSED.new('connection refused'))
    e = assert_raises(GLogin::ConnectionError) { auth.user('437849732894732') }
    assert_kind_of(Errno::ECONNREFUSED, e.cause)
  end

  def test_wraps_timeout_on_token_exchange
    auth = GLogin::Auth.new('1234', '4433', 'https://example.org')
    stub_request(:post, 'https://github.com/login/oauth/access_token')
      .to_raise(Net::OpenTimeout.new('execution expired'))
    assert_raises(GLogin::ConnectionError) { auth.user('437849732894732') }
  end
end
