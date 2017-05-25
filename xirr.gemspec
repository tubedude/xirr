# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xirr/version'

Gem::Specification.new do |spec|
  spec.name        = 'xirr'
  spec.version     = Xirr::VERSION
  spec.authors     = ['tubedude']
  spec.email       = ['beto@trevisan.me']
  spec.summary     = %q{Calculates XIRR (Bisection and Newton method) of a cashflow}
  spec.description = %q{Calculates IRR of a Cashflow, similar to Excel's, XIRR formula. It defaults to Newton Method, but will calculate Bisection as well.}
  spec.homepage    = 'https://github.com/tubedude/xirr'
  spec.license     = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10'

  spec.required_ruby_version = '>=2.2.2'
  spec.add_dependency 'activesupport', '>= 4.2', '<= 5.2'
  spec.add_development_dependency 'minitest', '~> 5.4'
  spec.add_development_dependency 'coveralls', '~> 0'

end
