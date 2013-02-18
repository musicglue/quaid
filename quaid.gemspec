# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'quaid/version'

Gem::Specification.new do |gem|
  gem.name          = "quaid"
  gem.version       = Quaid::VERSION
  gem.authors       = ["John Maxwell", "Adam Carlisle", "Lee M Hesnon", "Grumpy Cat"]
  gem.email         = ["john@musicglue.com", "adam@musicglue.com"]
  gem.description   = %q{Total Recall for Mongoid}
  gem.summary       = %q{...}
  gem.homepage      = "https://github.com/musicglue/quaid"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'mongoid', '~> 3.1.0'
  gem.add_dependency 'activesupport', '~> 3.2.12'
end
