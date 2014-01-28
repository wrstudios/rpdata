# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rpdata/version'

Gem::Specification.new do |spec|
  spec.name          = "rpdata"
  spec.version       = Rpdata::VERSION
  spec.authors       = ["Fabio Vilela"]
  spec.email         = ["fbvilela@gmail.com"]
  spec.description   = "Rpdata api wrapper"
  spec.summary       = "Gem to consume the rpdata wsdl"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec'
  spec.add_runtime_dependency 'savon' 
  spec.add_dependency 'activesupport'
  spec.add_dependency 'aspector'
end



