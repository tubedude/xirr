require 'xirr/version'
require 'active_support/configurable'
require 'xirr/config'
require 'xirr/main'

# @abstract adds a {Xirr::Cashflow} and {Xirr::Transaction} classes to calculate IRR of irregular transactions.
# Calculates Xirr
module Xirr

  autoload :Transaction,  'xirr/transaction'
  autoload :Cashflow,     'xirr/cashflow'

end
