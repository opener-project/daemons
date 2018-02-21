require File.expand_path('../lib/opener/daemons/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name        = 'opener-daemons'
  spec.version     = Opener::Daemons::VERSION
  spec.authors     = ['Wilco van Duinkerken', 'Olery']
  spec.email       = ['wilco@sparkboxx.com', 'development@olery.com']
  spec.summary     = 'Toolkit for turning OpeNER components into daemons'
  spec.description = spec.summary
  spec.homepage    = 'http://opener-project.github.io'
  spec.license     = 'Apache 2.0'

  spec.required_ruby_version = '>= 1.9.2'

  spec.files = Dir.glob([
    'config/**/*',
    'lib/**/*',
    'schema/**/*',
    'LICENSE.txt',
    '*.gemspec',
    'README.md'
  ]).select { |file| File.file?(file) }

  spec.add_dependency 'aws-sdk', '~> 2.0'
  spec.add_dependency 'slop', '~> 3.0'
  spec.add_dependency 'opener-callback-handler', '~> 1.1'
  spec.add_dependency 'opener-core', '~> 2.3'
  spec.add_dependency 'newrelic_rpm'
  spec.add_dependency 'json-schema'
  spec.add_dependency 'rollbar', '~> 1.0'
  spec.add_dependency 'oni', '~> 4.0'
  spec.add_dependency 'oga', '~> 1.0'

  spec.add_dependency 'httpclient', ['~> 2.0', '>= 2.5.3.3']

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
