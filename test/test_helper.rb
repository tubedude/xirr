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
  @x = Cashflow.new
      @x << Transaction.new(-10000.0, :date => Date.new(2014,4,15))
      @x << Transaction.new(-10000.0, :date => Date.new(2014,04,16))
      @x << Transaction.new(305.6, :date => Date.new(2014,05,16))
      @x << Transaction.new(9800.07, :date => Date.new(2014,06,15))
      @x << Transaction.new(5052.645, :date => Date.new(2014,06,15))
@x.xirr

  cf << Transaction.new(1000000, date: Date.today - 180)
  cf << Transaction.new(-2200000, date: Date.today - 60)
  cf << Transaction.new(-800000, date: Date.today - 30)
  cf.xirr

=end
