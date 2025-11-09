Gem::Specification.new do |s|
  s.name = 'bcrypt_pbkdf'
  s.version = '1.1.1'

  s.summary = "OpenBSD's bcrypt_pbkdf (a variant of PBKDF2 with bcrypt-based PRF)"
  s.description = <<-EOF
    This gem implements bcrypt_pbkdf (a variant of PBKDF2 with bcrypt-based PRF)
  EOF

  s.files = `git ls-files`.split("\n")
  s.require_path = 'lib'

  s.add_development_dependency 'rake-compiler', '~> 1.2.5'
  s.add_development_dependency 'minitest', '~> 5'
  s.add_development_dependency 'openssl', '~> 3'
  s.add_development_dependency 'rdoc', '~> 6'
  s.add_development_dependency 'rake-compiler-dock', '~> 1.5.0'

  s.rdoc_options += ['--title', 'bcrypt_pbkdf', '--line-numbers', '--inline-source', '--main', 'README.md']
  s.extra_rdoc_files += ['README.md', 'COPYING', 'CHANGELOG.md', *Dir['lib/**/*.rb']]

  s.extensions = 'ext/mri/extconf.rb'

  s.authors = ["Miklos Fazekas"]
  s.email = "mfazekas@szemafor.com"
  s.homepage = "https://github.com/net-ssh/bcrypt_pbkdf-ruby"
  s.license = "MIT"
end
