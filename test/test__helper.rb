# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

$stdout.sync = true

require 'simplecov'
require 'simplecov-cobertura'
unless SimpleCov.running || ENV['PICKS']
  SimpleCov.command_name('test')
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::CoberturaFormatter
    ]
  )
  SimpleCov.minimum_coverage 100
  SimpleCov.minimum_coverage_by_file 95
  SimpleCov.start do
    add_filter 'test/'
    add_filter 'vendor/'
    add_filter 'target/'
    track_files 'lib/**/*.rb'
    track_files '*.rb'
  end
end

require 'minitest/autorun'
require 'minitest/reporters'
require 'net/http'
require 'webmock/minitest'
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]
Minitest.load :minitest_reporter

# Test helper that records every Net::HTTP instance created inside a block,
# so tests can inspect their configuration (e.g. SSL verify_mode).
module HttpSpy
  def self.record
    clients = []
    original = Net::HTTP.method(:new)
    Net::HTTP.define_singleton_method(:new) do |*args, **kwargs|
      instance = original.call(*args, **kwargs)
      clients << instance
      instance
    end
    begin
      yield
    ensure
      Net::HTTP.define_singleton_method(:new, original)
    end
    clients
  end
end
