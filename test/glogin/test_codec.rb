# frozen_string_literal: true

#
# Copyright (c) 2017-2023 Yegor Bugayenko
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
require 'base64'
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

  def test_encrypts_into_plain_string
    text = GLogin::Codec.new('6hFGrte5LLmwi').encrypt("K&j\n\n\tuIpwp00{]=")
    assert(text =~ /^[a-zA-Z0-9]+$/, text)
    assert(!text.include?("\n"), text)
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
