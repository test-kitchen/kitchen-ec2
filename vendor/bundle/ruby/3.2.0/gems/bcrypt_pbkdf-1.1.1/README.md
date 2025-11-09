# bcrypt_pbkdf-ruby

bcrypt_pbkdf is a ruby gem implementing bcrypt_pbkdf from OpenBSD. This is currently used by net-ssh to read password encrypted Ed25519 keys.

[![Build Status](https://github.com/net-ssh/bcrypt_pbkdf-ruby/actions/workflows/ci.yml/badge.svg?branch=master&event=push)](https://github.com/net-ssh/bcrypt_pbkdf-ruby/actions/workflows/ci.yml)

## Acknowledgements

* The gut of the code is based on OpenBSD's bcrypt_pbkdf.c implementation
* Some ideas/code were taken adopted bcrypt-ruby: https://github.com/codahale/bcrypt-ruby

## Links

* http://www.tedunangst.com/flak/post/bcrypt-pbkdf
* http://cvsweb.openbsd.org/cgi-bin/cvsweb/src/lib/libutil/bcrypt_pbkdf.c?rev=1.13&content-type=text/x-cvsweb-markup

## Building

For windows and osx cross build make sure you checked out the gem source under the home directory and have docker installed.

```sh
gem install rake-compiler-dock
```

```sh
bundle exec rake compile
bundle exec rake test
bundle exec rake clean clobber
bundle exec rake gem:all
bundle exec rake release
bundle exec rake gem:release
```
