# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'redfish/version'

Gem::Specification.new do |s|
  s.name               = %q{redfish}
  s.version            = Redfish::VERSION
  s.platform           = Gem::Platform::RUBY

  s.authors            = ['Peter Donald']
  s.email              = %q{peter@realityforge.org}

  s.homepage           = %q{https://github.com/realityforge/redfish}
  s.summary            = %q{A lightweight library for configuring GlassFish/Payara servers.}
  s.description        = %q{A lightweight library for configuring GlassFish/Payara servers.}

  s.rubyforge_project  = %q{redfish}

  s.files              = `git ls-files`.split("\n")
  s.test_files         = `git ls-files -- {spec}/*`.split("\n")
  s.executables        = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.default_executable = []
  s.require_paths      = %w(lib)

  s.has_rdoc           = false
  s.rdoc_options       = %w(--line-numbers --inline-source --title redfish)

  s.add_development_dependency(%q<minitest>, ['= 5.0.2'])
  s.add_development_dependency(%q<mocha>, ['= 0.14.0'])
end
