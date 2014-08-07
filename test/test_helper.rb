require 'coveralls'
Coveralls.wear!

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

=begin

require 'active_support/all'
require_relative 'lib/xirr.rb'
require_relative 'lib/xirr/config.rb'
require_relative 'lib/xirr/base.rb'
require_relative 'lib/xirr/bisection.rb'
require_relative 'lib/xirr/newton_method.rb'
require_relative 'lib/xirr/cashflow.rb'
require_relative 'lib/xirr/transaction.rb'
include Xirr
  cf = Cashflow.new
  cf << Transaction.new(1000, date: '1985-01-01'.to_date)
  cf << Transaction.new(-6000, date: '1985-01-02'.to_date)
  cf.xirr(0.15)

=end
