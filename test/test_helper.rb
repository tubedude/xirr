require 'coveralls'
Coveralls.wear!

require 'minitest/autorun'
require 'minitest/spec'

require 'active_support/all'

require 'xirr/config.rb'
require 'xirr/main.rb'
require 'xirr/cashflow.rb'
require 'xirr/transaction.rb'
include Xirr
