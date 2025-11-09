# Net::SSH::Gateway

<em><b>Please note: this project is in maintenance mode. It is not under active development but pull requests are very much welcome. Just be sure to include tests!</b></em>

* Docs: http://net-ssh.github.com/net-ssh-gateway
* Issues: https://github.com/net-ssh/net-ssh-gateway/issues
* Codes: https://github.com/net-ssh/net-ssh-gateway
* Email: net-ssh@solutious.com

<em>As of v1.1.1, all gem releases are signed. See INSTALL.</em>


## DESCRIPTION:

Net::SSH::Gateway is a library for programmatically tunnelling connections to servers via a single "gateway" host. It is useful for establishing Net::SSH connections to servers behind firewalls, but can also be used to forward ports and establish connections of other types, like HTTP, to servers with restricted access.

## FEATURES:

* Easily manage forwarded ports
* Establish Net::SSH connections through firewalls

## SYNOPSIS:

In a nutshell:

  require 'net/ssh/gateway'

  gateway = Net::SSH::Gateway.new('host', 'user')

  gateway.ssh("host.private", "user") do |ssh|
    puts ssh.exec!("hostname")
  end

  gateway.open("host.private", 80) do |port|
    Net::HTTP.get_print("127.0.0.1", "/path", port)
  end

  gateway.shutdown!

  # As of 1.1.0, you can also specify the wait time for the
  # gateway thread with the :loop_wait option.
  gateway = Net::SSH::Gateway.new('host', 'user', :loop_wait => 0.001)

See Net::SSH::Gateway for more documentation.

## REQUIREMENTS:

* net-ssh (version 2)

If you want to run the tests or use any of the Rake tasks, you'll need:

* Echoe (for the Rakefile)
* Mocha (for the tests)

## INSTALL:

    $ gem install net-ssh-gateway

However, in order to be sure the code you're installing hasn't been tampered with, it's recommended that you verify the [signature](http://guides.rubygems.org/security/). To do this, you need to add the project's public key as a trusted certificate (you only need to do this once):

    # Add the public key as a trusted certificate
    # (You only need to do this once)
    $ curl -O https://raw.githubusercontent.com/net-ssh/net-ssh-gateway/master/net-ssh-public_cert.pem
    $ gem cert --add net-ssh-public_cert.pem

Then, when install the gem, do so with high security:

    $ gem install net-ssh-gateway -P HighSecurity

If you don't add the public key, you'll see an error like "Couldn't verify data signature".

## Ruby 1.9

As of release 2.0.0, net-ssh-gateway supports only Ruby >= 2.0.0. The last release that supports Ruby 1.9 is 1.3.0.


## LICENSE:

(The MIT License)

Copyright (c) 2008 Jamis Buck <jamis@37signals.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
