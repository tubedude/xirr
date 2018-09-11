require 'benchmark'
require 'active_support/all'
require 'xirr/config.rb'
require 'xirr/base.rb'
require 'xirr/bisection.rb'
require 'xirr/newton_method.rb'
require 'xirr/cashflow.rb'
require 'xirr/transaction.rb'
include Xirr

@cf = Cashflow.new
@cf << Transaction.new(1000, date: '1985-01-01'.to_date)
@cf << Transaction.new(-600, date: '1990-01-01'.to_date)
@cf << Transaction.new(-6000, date: '1995-01-01'.to_date)



n = 100
Benchmark.bm do |x|
  x.report { for i in 1..n; @cf.xirr(method: :bisection); end }
#   x.report { n.times do   ; a = "1"; end }
#   x.report { 1.upto(n) do ; a = "1"; end }
end