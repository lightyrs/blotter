# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blotter/version'

Gem::Specification.new do |gem|
  gem.name          = "blotter"
  gem.version       = Blotter::VERSION
  gem.authors       = ["Harris Novick"]
  gem.email         = ["harris@harrisnovick.com"]
  gem.description   = %q{blotter implements a basic router for Facebook page tab applications as well as some convenience methods that should come in handy for those deploying Facebook page tab applications on multiple, disconnected Facebook pages.}
  gem.summary       = %q{Router and convenience methods for Facebook page tab applications.}
  gem.homepage      = "http://switchrails.com"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "shoulda-matchers"
end
