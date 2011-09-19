# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'ymaps/version'

Gem::Specification.new do |s|
  s.name        = 'ymaps'
  s.version     = YMaps::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Alexander Semyonov']
  s.email       = ['al@semyonov.us']
  s.homepage    = 'http://github.com/rotuka/ymaps'
  s.summary     = %q{Helpers for using YMaps}
  s.description = %q{Different helpers for generating YMapsML, using YMaps widgets and geocoding via Yandex.Maps}

  s.rubyforge_project = 'ymaps'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('geokit',              '~> 1.5')

  s.add_development_dependency('shoulda', '>= 0')
  s.add_development_dependency('yard',    '>= 0')
end
