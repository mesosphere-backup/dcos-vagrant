# coding: utf-8

version = '1.2.0'

Gem::Specification.new do |s|
  s.name        = 'semi_semantic'
  s.version     = version
  s.platform    = Gem::Platform::RUBY
  s.summary     = 'Semi Semantic'
  s.description = "Semi Semantic\n#{`git rev-parse HEAD`[0, 6]}"
  s.author      = 'Pivotal'
  s.homepage    = 'https://github.com/pivotal-cf-experimental/semi_semantic'
  s.license     = 'Apache 2.0'
  s.email       = 'support@cloudfoundry.com'
  s.required_ruby_version = Gem::Requirement.new('>= 1.9.3')

  s.files        = `git ls-files -- bin/* lib/*`.split("\n") + %w(README.md)
  s.require_path = 'lib'
  s.bindir       = 'bin'

  s.add_development_dependency 'rspec', '~> 3.0.0.rc'
  s.add_development_dependency 'rspec-legacy_formatters', '1.0.0.rc1'
end
