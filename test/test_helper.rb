$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'minitest/autorun'
require 'minitest/spec'

require 'active_support/all'

require 'xirr/config.rb'
require 'xirr/base.rb'
require 'xirr/rtsafe.rb'
require 'xirr/rtsafe_c.rb'
require 'xirr/brent.rb'
require 'xirr/bisection.rb'
require 'xirr/newton_method.rb'
require 'xirr/cashflow.rb'
require 'xirr/transaction.rb'
require 'xirr/periodic.rb'
require 'xirr/tvm.rb'
require 'xirr/rates.rb'
require 'xirr/bonds.rb'
require 'xirr/depreciation.rb'
require 'xirr/returns.rb'
include Xirr

