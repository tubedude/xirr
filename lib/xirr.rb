require 'xirr/version'
require 'active_support/configurable'
require 'xirr/config'
require 'xirr/base'
require 'xirr/rtsafe'
require 'xirr/rtsafe_c'
require 'xirr/brent'
require 'xirr/bisection'
require 'xirr/newton_method'
require 'xirr/periodic'
require 'xirr/tvm'
require 'xirr/rates'
require 'xirr/bonds'
require 'xirr/depreciation'
require 'xirr/returns'

# @abstract adds a {Xirr::Cashflow} and {Xirr::Transaction} classes to calculate IRR of irregular transactions.
# Calculates Xirr
module Xirr
  autoload :Transaction, 'xirr/transaction'
  autoload :Cashflow, 'xirr/cashflow'
end
