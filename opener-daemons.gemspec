# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opener/daemons/version'

Gem::Specification.new do |spec|
  spec.name          = "opener-daemons"
  spec.version       = Opener::Daemons::VERSION
  spec.authors       = ["Wilco van Duinkerken"]
  spec.email         = ["wilco@sparkboxx.com"]
  spec.summary       = %q{Daemonize OpeNER components and make them read from an SQS queue. JRuby compatible.}
  spec.description   = spec.summary
  spec.homepage      = "http://opener-project.github.io"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]


  spec.add_dependency 'aws-sdk-core'
  spec.add_dependency 'spoon'

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
