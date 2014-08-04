require 'xirr/version'
require 'active_support/configurable'
require 'xirr/config'
require 'xirr/main'

module Xirr

  autoload :Transaction,  'xirr/transaction'
  autoload :Cashflow,     'xirr/cashflow'

end
