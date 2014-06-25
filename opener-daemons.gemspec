require File.expand_path('../lib/opener/daemons/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name        = "opener-daemons"
  spec.version     = Opener::Daemons::VERSION
  spec.authors     = ["Wilco van Duinkerken"]
  spec.email       = ["wilco@sparkboxx.com"]
  spec.summary     = %q{Daemonize OpeNER components and make them read from an SQS queue. JRuby compatible.}
  spec.description = spec.summary
  spec.homepage    = "http://opener-project.github.io"
  spec.license     = "Apache 2.0"

  spec.files = Dir.glob([
    'lib/**/*',
    'LICENSE.txt',
    '*.gemspec',
    'README.md'
  ]).select { |file| File.basename(file) }

  spec.add_dependency 'aws-sdk-core'
  spec.add_dependency 'spoon'
  spec.add_dependency 'dotenv'

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
