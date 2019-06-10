require 'xirr/version'
require 'bigdecimal'
require 'active_support/configurable'
require 'active_support/concern'
require 'xirr/config'
require 'xirr/base'
require 'xirr/bisection'
require 'xirr/newton_method'

# @abstract adds a {Xirr::Cashflow} and {Xirr::Transaction} classes to calculate IRR of irregular transactions.
# Calculates Xirr
module Xirr
  autoload :Transaction, 'xirr/transaction'
  autoload :Cashflow, 'xirr/cashflow'
end
