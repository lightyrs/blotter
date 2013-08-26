# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blotter/version'

Gem::Specification.new do |spec|
  spec.name          = "blotter"
  spec.version       = Blotter::VERSION
  spec.authors       = ["Harris Novick"]
  spec.email         = ["harris@lightyrs.com"]
  spec.description   = %q{Router and convenience methods for Rails apps managing multiple Facebook page applications.}
  spec.summary       = %q{Simple Facebook Page Applications with Rails}
  spec.homepage      = "http://github.com/lightyrs"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", "~> 3.2"
  spec.add_runtime_dependency "actionpack", "~> 3.2"
  spec.add_runtime_dependency "koala", "~> 1.5.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "rr"
  spec.add_development_dependency "shoulda-matchers"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "nyan-cat-formatter"
end
