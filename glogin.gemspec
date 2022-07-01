# frozen_string_literal: true

# Copyright (c) 2017-2022 Yegor Bugayenko
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

require 'English'

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/glogin/version'

Gem::Specification.new do |s|
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = '~>2.3'
  s.name = 'glogin'
  s.version = GLogin::VERSION
  s.license = 'MIT'
  s.summary = 'Login/logout via GitHub OAuth for your web app'
  s.description = 'Enables login/logout functionality for a Ruby web app'
  s.authors = ['Yegor Bugayenko']
  s.email = 'yegor256@gmail.com'
  s.homepage = 'http://github.com/yegor256/glogin'
  s.files = `git ls-files`.split($RS)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = ['README.md', 'LICENSE.txt']
  s.add_runtime_dependency 'base58', '0.2.3'
  s.add_development_dependency 'codecov', '0.6.0'
  s.add_development_dependency 'minitest', '5.16.1'
  s.add_development_dependency 'rake', '13.0.6'
  s.add_development_dependency 'rdoc', '6.4.0'
  s.add_development_dependency 'rspec-rails', '5.1.2'
  s.add_development_dependency 'rubocop', '1.31.1'
  s.add_development_dependency 'rubocop-rspec', '2.11.1'
  s.add_development_dependency 'webmock', '3.14.0'
  s.metadata['rubygems_mfa_required'] = 'true'
end
