# frozen_string_literal: true

#
# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'glogin/version'
require_relative 'glogin/auth'
require_relative 'glogin/cookie'

# GLogin main module.
#
# GLogin is a Ruby gem that provides OAuth integration with GitHub. It simplifies
# the process of authenticating users through GitHub and managing their sessions
# using secure cookies.
#
# @example Basic usage with Sinatra
#   require 'sinatra'
#   require 'glogin'
#   
#   configure do
#     set :glogin, GLogin::Auth.new(
#       ENV['GITHUB_CLIENT_ID'],
#       ENV['GITHUB_CLIENT_SECRET'],
#       'http://localhost:4567/auth'
#     )
#   end
#   
#   get '/auth' do
#     user = settings.glogin.user(params[:code])
#     cookie = GLogin::Cookie::Open.new(user, ENV['ENCRYPTION_SECRET'])
#     response.set_cookie('glogin', cookie.to_s)
#     redirect '/'
#   end
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
module GLogin
end
