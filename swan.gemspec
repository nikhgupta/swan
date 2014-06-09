# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'swan/version'

Gem::Specification.new do |spec|
  spec.name          = "swan"
  spec.version       = Swan::VERSION
  spec.authors       = ["Nikhil Gupta"]
  spec.email         = ["me@nikhgupta.com"]
  spec.description   = %q{Download online stuff with poise.}
  spec.summary       = %q{Download online stuff with poise.}
  spec.homepage      = "http://github.com/nikhgupta/swan"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry" # debugging

  spec.add_dependency "thor"            # cli app
  spec.add_dependency "parallel"        # parallel execution
  spec.add_dependency "mechanize"       # downloader/scraper
  spec.add_dependency "taglib-ruby"     # music related gem
  spec.add_dependency "activesupport"   # supporting gem
end
