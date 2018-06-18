[![Managed by Zerocracy](https://www.0crat.com/badge/C3RFVLU72.svg)](https://www.0crat.com/p/C3RFVLU72)
[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/glogin)](http://www.rultor.com/p/yegor256/glogin)
[![We recommend RubyMine](http://img.teamed.io/rubymine-recommend.svg)](https://www.jetbrains.com/ruby/)

[![Build Status](https://travis-ci.org/yegor256/glogin.svg)](https://travis-ci.org/yegor256/glogin)
[![PDD status](http://www.0pdd.com/svg?name=yegor256/glogin)](http://www.0pdd.com/p?name=yegor256/glogin)
[![Gem Version](https://badge.fury.io/rb/glogin.svg)](http://badge.fury.io/rb/glogin)
[![Maintainability](https://api.codeclimate.com/v1/badges/155f86b639d155259219/maintainability)](https://codeclimate.com/github/yegor256/glogin/maintainability)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/glogin.svg)](https://codecov.io/github/yegor256/glogin?branch=master)

## GitHub Login for Ruby web app

This simple gem will help you enable login/logout through
[GitHub OAuth](https://developer.github.com/apps/building-integrations/setting-up-and-registering-oauth-apps/)
for your web application. This is how it works with
[Sinatra](http://www.sinatrarb.com/),
but you can do something similar in any framework.

First, somewhere in the global space, before the app starts:

```ruby
require 'glogin'
configure do
  set :glogin, GLogin::Auth.new(
    # Make sure their values are coming from a secure
    # place and are not visible in the source code:
    client_id, client_secret,
    # This is what you will register in GitHub as an
    # authorization callback URL:
    'http://www.example.com/github-callback'
  )
end
```

Next, for all web pages we need to parse a cookie, if it exists,
and convert it into a user:

```ruby
require 'sinatra/cookies'
before '/*' do
  if cookies[:glogin]
    begin
      @user = GLogin::Cookie::Closed.new(
        cookies[:glogin],
        # This must be some long text to be used to
        # encrypt the value in the cookie.
        secret
      ).to_user
    rescue OpenSSL::Cipher::CipherError => _
      # Nothing happens here, the user is not logged in.
      cookies.delete(:glogin)
    end
  end
end
```

If the `glogin` cookie is coming in and contains a valid data,
a local variable `@user` will be set to something like this:

```ruby
{ login: 'yegor256', avatar: 'http://...' }
```

Next, we need a URL for GitHub OAuth callback:

```ruby
get '/github-callback' do
  cookies[:glogin] = GLogin::Cookie::Open.new(
    settings.glogin.user(params[:code]),
    # The same encryption secret that we were using above:
    secret
  ).to_s
  redirect to('/')
end
```

Finally, we need a logout URL:

```ruby
get '/logout' do
  cookies.delete(:glogin)
  redirect to('/')
end
```

It is recommended to provide the third "context" parameter to
`GLogin::Cookie::Closed` and `GLogin::Cookie::Open` constructors, in order
to enforce stronger security. The context may include the `User-Agent`
HTTP header of the user, their IP address, and so on. When anything
changes on the user side, they will be forced to re-login.

One more thing is the login URL you will need for your front page. Here
it is:

```ruby
settings.glogin.login_uri
```

For unit testing you can just provide an empty string as a `secret` for
`GLogin::Cookie::Open` and `GLogin::Cookie::Closed` and the encryption will be disabled:
whatever will be coming from the cookie will be trusted. For testing
it will be convenient to provide a user name in a query string, like:

```
http://localhost:9292/?glogin=tester
```

To enable that, it's recommended to add this line (see how
it works in [zold-io/wts.zold.io](https://github.com/zold-io/wts.zold.io)):

```ruby
require 'sinatra/cookies'
before '/*' do
  cookies[:glogin] = params[:glogin] if params[:glogin]
  if cookies[:glogin]
    # same as above
  end
end
```

I use this gem in [sixnines](https://github.com/yegor256/sixnines)
and [0pdd](https://github.com/yegor256/0pdd) web apps (both open source),
on top of Sinatra.

For better security it is recommended to use "bearer" codes.
First, you create a global map of that codes, somewhere where your
application starts (I'm using [`Concurrent::Map`](https://ruby-concurrency.github.io/concurrent-ruby/Concurrent/Map.html)):

```ruby
require 'concurrent'
configure do
  set :bearers, Concurrent::Map.new
end
```

Then, you pass a context to the `user()` method and save the bearer
code in the map:

```ruby
get '/github-callback' do
  user = settings.glogin.user(params[:code], "#{request.ip} #{request.user_agent}")
  settings.bearers[user[:login]] = user[:bearer]
  cookies[:glogin] = GLogin::Cookie::Open.new(user, secret).to_s
  redirect to('/')
end
```

Finally, you make sure that the incoming cookie has the right bearer code:

```ruby
before '/*' do
  if cookies[:glogin]
    begin
      user = GLogin::Cookie::Closed.new(
        cookies[:glogin], secret
      ).to_user
      if user[:bearer] == settings.bearers[user[:login]]
        @user = user
      end
    rescue OpenSSL::Cipher::CipherError => _
      cookies.delete(:glogin)
    end
  end
```

Now it will not be possible to login from a different, even if the cookie is known.


Also, you can use `GLogin::Codec` just to encrypt/decrypt a piece of text:

```ruby
require 'glogin/codec'
codec = GLogin:Codec.new('the secret')
encrypted = codec.encrypt('Hello, world!')
decrypted = codec.decrypt(encrypted)
```

## How to contribute?

Just submit a pull request. Make sure `rake` passes.

## License

(The MIT License)

Copyright (c) 2017-2018 Yegor Bugayenko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
