# -*- encoding: utf-8 -*-
# stub: net-scp 4.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "net-scp".freeze
  s.version = "4.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/net-ssh/net-scp/blob/master/CHANGES.txt" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jamis Buck".freeze, "Delano Mandelbaum".freeze, "Mikl\u00F3s Fazekas".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDeDCCAmCgAwIBAgIBATANBgkqhkiG9w0BAQsFADBBMQ8wDQYDVQQDDAZuZXRz\nc2gxGTAXBgoJkiaJk/IsZAEZFglzb2x1dGlvdXMxEzARBgoJkiaJk/IsZAEZFgNj\nb20wHhcNMjQxMjI1MTEzNDQ3WhcNMjUxMjI1MTEzNDQ3WjBBMQ8wDQYDVQQDDAZu\nZXRzc2gxGTAXBgoJkiaJk/IsZAEZFglzb2x1dGlvdXMxEzARBgoJkiaJk/IsZAEZ\nFgNjb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDGJ4TbZ9H+qZ08\npQfJhPJTHaDCyQvCsKTFrL5O9z3tllQ7B/zksMMM+qFBpNYu9HCcg4yBATacE/PB\nqVVyUrpr6lbH/XwoN5ljXm+bdCfmnjZvTCL2FTE6o+bcnaF0IsJyC0Q2B1fbWdXN\n6Off1ZWoUk6We2BIM1bn6QJLxBpGyYhvOPXsYoqSuzDf2SJDDsWFZ8kV5ON13Ohm\nJbBzn0oD8HF8FuYOewwsC0C1q4w7E5GtvHcQ5juweS7+RKsyDcVcVrLuNzoGRttS\nKP4yMn+TzaXijyjRg7gECfJr3TGASaA4bQsILFGG5dAWcwO4OMrZedR7SHj/o0Kf\n3gL7P0axAgMBAAGjezB5MAkGA1UdEwQCMAAwCwYDVR0PBAQDAgSwMB0GA1UdDgQW\nBBQF8qLA7Z4zg0SJGtUbv3eoQ8tjIzAfBgNVHREEGDAWgRRuZXRzc2hAc29sdXRp\nb3VzLmNvbTAfBgNVHRIEGDAWgRRuZXRzc2hAc29sdXRpb3VzLmNvbTANBgkqhkiG\n9w0BAQsFAAOCAQEAOEVGPubOS9dBQmiJYIZHOXe2Q50iQgxKa7hyEJcyA7q69Q5h\nHa5r4WpZyW0Dkr0+jIkT8GS7hO0XnUZdOiuNFQrx30jfRSVT7680dF6wAHEQZJqC\nZmYFthhR/mtzi7bA+Ubd0PyBNivqt3WhWP+Z19j1bVWIwzczUcFFao+FBjXptI0m\nVGRPnRIzATA2qQUuKGkwrNFSHD9tDIHXSvwJ62U9ahoMKfMoDP0WHdPIpFCB8bPg\nwxMvGTA/RH93o6dL09sq7rVtsS9NNFmBGJWLZWWPfcspNBUXS0HTWXsWS9XTm2bm\nbbXS+I4xE1yFIPs39ej57LGJDMgMhWTyJF2zVg==\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2025-01-22"
  s.description = "A pure Ruby implementation of the SCP client protocol".freeze
  s.email = ["net-ssh@solutious.com".freeze]
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/net-ssh/net-scp".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A pure Ruby implementation of the SCP client protocol.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 3

  s.add_runtime_dependency(%q<net-ssh>.freeze, [">= 2.6.5", "< 8.0.0"])
  s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
  s.add_development_dependency(%q<mocha>.freeze, [">= 0"])
end
