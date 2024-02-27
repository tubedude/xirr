$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'coveralls'
# Coveralls.wear!

require 'minitest/autorun'
require 'minitest/spec'

require 'active_support/all'

require 'xirr/config.rb'
require 'xirr/base.rb'
require 'xirr/bisection.rb'
require 'xirr/newton_method.rb'
require 'xirr/cashflow.rb'
require 'xirr/transaction.rb'
include Xirr

