# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

VERSION = begin 
            require 'choosy/version'
            Choosy::Version.load_from_lib
          rescue LoadError
            '0'
          end

Gem::Specification.new do |s|
  s.name        = "hash_object"
  s.version     = VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Gabe McArthur"]
  s.email       = ["madeonamac@gmail.com"]
  s.homepage    = "http://github.com/gabemc/hash_object"
  s.summary     = %q{A stupid meta tool for mapping existing hash objects into real objects, for convenience.}
  s.description = %q{A stupid meta tool for mapping existing hash objects into real objects, for convenience.}

  s.rubyforge_project = "hash-object"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
