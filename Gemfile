source 'https://rubygems.org'

# Specify your gem's dependencies in xirr.gemspec
gemspec

# Pin one ActiveSupport line to test against it, as CI does:
#   ACTIVESUPPORT=8.1 bundle update activesupport && bundle exec rake
if (activesupport = ENV['ACTIVESUPPORT'])
  gem 'activesupport', "~> #{activesupport}.0"
end
