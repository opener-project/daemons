if RUBY_VERSION < '2.4.0'
  require 'rubygems/util'
  Zlib.send :define_singleton_method, :gzip,   &Gem::Util.method(:gzip)
  Zlib.send :define_singleton_method, :gunzip, &Gem::Util.method(:gunzip)
end
