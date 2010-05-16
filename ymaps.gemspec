# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ymaps}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alexander Semyonov"]
  s.date = %q{2010-04-03}
  s.description = %q{Different helpers for generating YMapsML, using YMaps widgets and geocoding via Yandex.Maps}
  s.email = %q{rotuka@rotuka.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "init.rb",
     "lib/geokit/geocoders/yandex_geocoder.rb",
     "lib/ymaps.rb",
     "lib/ymaps/action_view.rb",
     "lib/ymaps/action_view/html_helper.rb",
     "lib/ymaps/action_view/ymapsml_helper.rb",
     "test/helper.rb",
     "test/test_ymaps.rb",
     "ymaps.gemspec"
  ]
  s.homepage = %q{http://github.com/rotuka/ymaps}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Helpers for using YMaps}
  s.test_files = [
    "test/helper.rb",
     "test/test_ymaps.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<yard>, [">= 0"])
      s.add_runtime_dependency(%q<geokit>, ["= 1.5.0"])
    else
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<yard>, [">= 0"])
      s.add_dependency(%q<geokit>, ["= 1.5.0"])
    end
  else
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<yard>, [">= 0"])
    s.add_dependency(%q<geokit>, ["= 1.5.0"])
  end
end
