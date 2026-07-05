# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xirr/version'

Gem::Specification.new do |spec|
  spec.name        = 'xirr'
  spec.version     = Xirr::VERSION
  spec.authors     = ['tubedude']
  spec.email       = ['beto@trevisan.me']
  spec.summary     = %q{XIRR and a finance toolkit for Ruby, built on a safeguarded-Newton solver}
  spec.description = %q{Calculates the XIRR of a cashflow (the internal rate of return for transactions on arbitrary dates, like Excel's XIRR) using a safeguarded-Newton solver, with an optional native C build. Also includes time-value-of-money, bond, depreciation, rate-conversion, and performance-metric functions.}
  spec.homepage    = 'https://github.com/tubedude/xirr'
  spec.license     = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # Optional native rtsafe solver. The build is best-effort (see extconf.rb); the
  # gem falls back to the pure-Ruby solver when it isn't compiled.
  spec.extensions    = ['ext/xirr/extconf.rb']

  spec.required_ruby_version = '>=3.1'

  spec.add_dependency 'activesupport', '>= 6.1', '< 8'

  spec.add_development_dependency 'minitest', '~> 5.14'
  spec.add_development_dependency 'bundler', '>= 2.2'
  spec.add_development_dependency 'rake', '~> 13.0'

end
