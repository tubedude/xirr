# @cf = Cashflow.new
# @cf << Transaction.new(105187.06,     date: '2011-12-07'.to_date )
# @cf << Transaction.new(816709.66,     date: '2011-12-07'.to_date )
# @cf << Transaction.new(479069.684,      date: '2011-12-07'.to_date )
# @cf << Transaction.new(937309.708,      date: '2012-01-18'.to_date )
# @cf << Transaction.new(88622.661,     date: '2012-07-03'.to_date )
# @cf << Transaction.new(100000.0,      date: '2012-07-03'.to_date )
# @cf << Transaction.new(80000.0,     date: '2012-07-19'.to_date )
# @cf << Transaction.new(403627.95,     date: '2012-07-23'.to_date )
# @cf << Transaction.new(508117.9,      date: '2012-07-23'.to_date )
# @cf << Transaction.new(789706.87,     date: '2012-07-23'.to_date )
# @cf << Transaction.new(-88622.661,      date: '2012-09-11'.to_date )
# @cf << Transaction.new(-789706.871,     date: '2012-09-11'.to_date )
# @cf << Transaction.new(-688117.9,     date: '2012-09-11'.to_date )
# @cf << Transaction.new(-403627.95,      date: '2012-09-11'.to_date )
# @cf << Transaction.new(403627.95,     date: '2012-09-12'.to_date )
# @cf << Transaction.new(789706.871,      date: '2012-09-12'.to_date )
# @cf << Transaction.new(88622.661,     date: '2012-09-12'.to_date )
# @cf << Transaction.new(688117.9,      date: '2012-09-12'.to_date )
# @cf << Transaction.new(45129.14,      date: '2013-03-11'.to_date )
# @cf << Transaction.new(26472.08,      date: '2013-03-11'.to_date )
# @cf << Transaction.new(51793.2,     date: '2013-03-11'.to_date )
# @cf << Transaction.new(126605.59,     date: '2013-03-11'.to_date )
# @cf << Transaction.new(278532.29,     date: '2013-03-28'.to_date )
# @cf << Transaction.new(99284.1,     date: '2013-03-28'.to_date )
# @cf << Transaction.new(58238.57,      date: '2013-03-28'.to_date )
# @cf << Transaction.new(113945.03,     date: '2013-03-28'.to_date )
# @cf << Transaction.new(405137.88,     date: '2013-05-21'.to_date )
# @cf << Transaction.new(-405137.88,      date: '2013-05-21'.to_date )
# @cf << Transaction.new(165738.23,     date: '2013-05-21'.to_date )
# @cf << Transaction.new(-165738.23,      date: '2013-05-21'.to_date )
# @cf << Transaction.new(144413.24,     date: '2013-05-21'.to_date )
# @cf << Transaction.new(84710.65,      date: '2013-05-21'.to_date )
# @cf << Transaction.new(-84710.65,     date: '2013-05-21'.to_date )
# @cf << Transaction.new(-144413.24,      date: '2013-05-21'.to_date )
#
#
# #
# # (0.0,2014-02-14)
# # (0.0,2014-02-14)
# # (0.0,2014-02-14)
# # (0.0,2014-02-14)
# # (0.0,2014-02-14)
# # (0.0,2014-02-14)
# # (0.0,2014-02-14)
# # (0.0,2014-02-14)
# # (0.0,2014-02-14)
# # (0.0,2014-02-14)
# # (0.0,2014-02-14)
# # (0.0,2014-02-14) (0.0,2014-02-14) (0.0,2014-02-14) (0.0,2014-02-14) (0.0,2014-08-12) (0.0,2014-08-12) (0.0,2014-08-12) (0.0,2014-08-12) (0.0,2014-08-12) (0.0,2014-08-12) (0.0,2014-08-12) (0.0,2014-08-12) (0.0,2014-08-12) (0.0,2014-08-12) (0.0,2014-08-12) (0.0,2014-08-12) (-0.0,2014-11-19)]



require 'active_support/all'
require_relative 'lib/xirr.rb'
require_relative 'lib/xirr/config.rb'
require_relative 'lib/xirr/base.rb'
require_relative 'lib/xirr/bisection.rb'
require_relative 'lib/xirr/newton_method.rb'
require_relative 'lib/xirr/cashflow.rb'
require_relative 'lib/xirr/transaction.rb'
include Xirr

require 'Benchmark'

@cf = Cashflow.new
@cf << Transaction.new(105187.06,     date: '2011-12-07'.to_date )
@cf << Transaction.new(816709.66,     date: '2011-12-07'.to_date )
@cf << Transaction.new(479069.684,      date: '2011-12-07'.to_date )
@cf << Transaction.new(937309.708,      date: '2012-01-18'.to_date )
@cf << Transaction.new(88622.661,     date: '2012-07-03'.to_date )

@cf << Transaction.new(100000.0,      date: '2012-07-03'.to_date )
@cf << Transaction.new(80000.0,     date: '2012-07-19'.to_date )
@cf << Transaction.new(403627.95,     date: '2012-07-23'.to_date )
@cf << Transaction.new(508117.9,      date: '2012-07-23'.to_date )
@cf << Transaction.new(789706.87,     date: '2012-07-23'.to_date )
@cf << Transaction.new(-88622.661,      date: '2012-09-11'.to_date )
@cf << Transaction.new(-789706.871,     date: '2012-09-11'.to_date )
@cf << Transaction.new(-688117.9,     date: '2012-09-11'.to_date )
@cf << Transaction.new(-403627.95,      date: '2012-09-11'.to_date )
@cf << Transaction.new(403627.95,     date: '2012-09-12'.to_date )
@cf << Transaction.new(789706.871,      date: '2012-09-12'.to_date )
@cf << Transaction.new(88622.661,     date: '2012-09-12'.to_date )

@cf << Transaction.new(688117.9,      date: '2012-09-12'.to_date )
@cf << Transaction.new(45129.14,      date: '2013-03-11'.to_date )
@cf << Transaction.new(26472.08,      date: '2013-03-11'.to_date )
@cf << Transaction.new(51793.2,     date: '2013-03-11'.to_date )
@cf << Transaction.new(126605.59,     date: '2013-03-11'.to_date )
@cf << Transaction.new(278532.29,     date: '2013-03-28'.to_date )
@cf << Transaction.new(99284.1,     date: '2013-03-28'.to_date )
@cf << Transaction.new(58238.57,      date: '2013-03-28'.to_date )
@cf << Transaction.new(113945.03,     date: '2013-03-28'.to_date )
@cf << Transaction.new(405137.88,     date: '2013-05-21'.to_date )

@cf << Transaction.new(-405137.88,      date: '2013-05-21'.to_date )
@cf << Transaction.new(165738.23,     date: '2013-05-21'.to_date )
@cf << Transaction.new(-165738.23,      date: '2013-05-21'.to_date )
@cf << Transaction.new(144413.24,     date: '2013-05-21'.to_date )
@cf << Transaction.new(84710.65,      date: '2013-05-21'.to_date )
@cf << Transaction.new(-8471000.65,     date: '2013-05-21'.to_date )
@cf << Transaction.new(-1444130.24,      date: '2013-05-21'.to_date )



def compact_cf
  compact = Hash.new
  @cf.map(&:date).uniq.each {|date| compact[date] = 0 }
  @cf.each { |flow| compact[flow.date] += flow.amount}
  @compact_cf = Cashflow.new compact.map { |key,value| Transaction.new(value, date: key.to_date)}
  @compact_cf.xirr(@compact_cf.irr_guess, :newton_method)
end




n = 100
Benchmark.bm (10) { |x|
  x.report('Compact') { n.times { @cf.xirr(nil, :newton_method, true) } }
  # x.report('Compact') { n.times { compact_cf } }
  x.report('Natural') { n.times { @cf.xirr(nil, :newton_method, false) } }
}
