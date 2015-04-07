# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'freespeed/version'

Gem::Specification.new do |spec|
  spec.name          = "freespeed"
  spec.version       = Freespeed::VERSION
  spec.authors       = ["punsa"]
  spec.email         = ["puneet.241994.agarwal@gmail.com"]
  spec.summary       = %q{This gem speeds up the reloading time in rails by swapping the content of FileUpdateChecker}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "rb-inotify"
  spec.add_development_dependency 'rake'
end
