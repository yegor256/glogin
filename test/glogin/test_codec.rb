# frozen_string_literal: true

#
# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'base64'
require_relative '../test__helper'
require_relative '../../lib/glogin/codec'

class TestCodec < Minitest::Test
  def test_encodes_and_decodes
    text = 'This is the text, дорогой товарищ'
    assert_equal(
      text,
      Base64.decode64(Base64.encode64(text)).force_encoding('UTF-8')
    )
  end

  def test_encrypts_and_decrypts
    crypt = GLogin::Codec.new('this is the secret key!')
    text = 'This is the text, товарищ'
    assert_equal(text, crypt.decrypt(crypt.encrypt(text)))
  end

  def test_decrypts_with_invalid_password
    assert_raises GLogin::Codec::DecodingError do
      GLogin::Codec.new('the wrong key').decrypt(
        GLogin::Codec.new('the right key').encrypt('the text')
      )
    end
  end

  def test_decrypts_broken_base58
    %w[abc0 abcO abcl abcI].each do |t|
      assert_raises GLogin::Codec::DecodingError do
        GLogin::Codec.new('some-key').decrypt(t)
      end
    end
  end

  def test_encrypts_into_plain_string
    text = GLogin::Codec.new('6hFGrte5LLmwi').encrypt("K&j\n\n\tuIpwp00{]=")
    assert_match(/^[a-zA-Z0-9]+$/, text, text)
    refute_includes(text, "\n", text)
  end

  def test_encrypts_using_base64
    codec = GLogin::Codec.new('6hFGrte5LLmwi', base64: true)
    text = 'Hello, world!'
    enc = codec.encrypt(text)
    assert_equal(text, codec.decrypt(enc))
  end

  def test_decrypts_broken_text
    assert_raises GLogin::Codec::DecodingError do
      GLogin::Codec.new('the key').decrypt('этот текст не был зашифрован')
    end
  end

  def test_decrypts_broken_text_with_empty_key
    assert_raises GLogin::Codec::DecodingError do
      GLogin::Codec.new('key').decrypt('')
    end
  end

  def test_encrypts_and_decrypts_with_empty_key
    crypt = GLogin::Codec.new
    text = 'This is the text, дорогой друг!'
    assert_equal(text, crypt.decrypt(crypt.encrypt(text)))
  end
end
