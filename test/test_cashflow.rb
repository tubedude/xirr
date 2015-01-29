require_relative 'test_helper'

describe 'Cashflows' do

  describe 'of an ok investment' do
    before(:all) do
      @cf = Cashflow.new
      @cf << Transaction.new(1000, date: '1985-01-01'.to_date)
      @cf << Transaction.new(-600, date: '1990-01-01'.to_date)
      @cf << Transaction.new(-6000, date: '1995-01-01'.to_date)
    end

    it 'has a sum of its transactions' do
      assert_equal '-5600'.to_f, @cf.sum
    end

    it 'with a wrong method is invalid' do
      assert_raises(ArgumentError) { @cf.xirr(nil, :no_method) }
    end

    it 'has an Internal Rate of Return on default Method' do
      assert_equal '0.225683'.to_f, @cf.xirr
    end

    it 'has an Internal Rate of Return on Bisection Method' do
      assert_equal '0.225683'.to_f, @cf.xirr(nil, :bisection)
    end

    it 'has an Internal Rate of Return on Bisection Method using a Guess' do
      assert_in_delta '0.225683'.to_f, @cf.xirr(0.15).to_f, 0.000002
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '0.225683'.to_f, @cf.xirr(nil, :newton_method)
    end

    it 'has an educated guess' do
      assert_equal '0.208'.to_f, @cf.irr_guess
    end
  end


  describe 'of an inverted ok investment' do
    before(:all) do
      @cf = Cashflow.new
      @cf << Transaction.new(-1000, date: '1985-01-01'.to_date)
      @cf << Transaction.new(600, date: '1990-01-01'.to_date)
      @cf << Transaction.new(6000, date: '1995-01-01'.to_date)
    end

    it 'has a sum of its transactions' do
      assert_equal '5600'.to_f, @cf.sum
    end

    it 'has an Internal Rate of Return on Bisection Method' do
      assert_equal '0.225683'.to_f, @cf.xirr(nil, :bisection)
    end

    it 'has an Internal Rate of Return on Bisection Method using a Guess' do
      assert_in_delta '0.225683'.to_f, @cf.xirr(0.15).to_f, 0.000002
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '0.225683'.to_f, @cf.xirr(nil, :newton_method)
    end

    it 'has an educated guess' do
      assert_equal '0.208'.to_f, @cf.irr_guess
    end
  end

  describe 'of a very good investment' do
    before(:all) do
      @cf = Cashflow.new
      @cf << Transaction.new(1000000, date: Date.today - 180)
      @cf << Transaction.new(-2200000, date: Date.today - 60)
      @cf << Transaction.new(-800000, date: Date.today - 30)
    end

    it 'has an Internal Rate of Return on Bisection Method' do
      assert_equal '22.352206  '.to_f, @cf.xirr(nil, :bisection)
    end

    it 'has a sum of its transactions' do
      assert_equal '-2000000'.to_f, @cf.sum
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '22.352206 '.to_f, @cf.xirr(nil, :newton_method)
    end

    it 'has an educated guess' do
      assert_equal '13.488 '.to_f, @cf.irr_guess
    end
  end

  describe 'of a good investment' do
    before(:all) do
      @cf = Cashflow.new
      @cf << Transaction.new(1000, date: '1985-01-01'.to_date)
      @cf << Transaction.new(-6000, date: '1985-01-02'.to_date)
    end

    it 'has an Internal Rate of Return on Bisection Method' do
      assert_equal '1.0597572345993451e+284'.to_f, @cf.xirr(nil, :bisection)
    end

    it 'has an Internal Rate of Return on Bisection Method using a bad Guess' do
      assert_raises(ArgumentError) { @cf.xirr(0.15, :bisection) }
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '1.0597572345993451e+284'.to_f, @cf.xirr(nil, :newton_method)
    end

    it 'has an educated guess' do
      assert_equal '1.0597572345993451e+284'.to_f, @cf.irr_guess
    end
  end

  describe 'an all-negative Cashflow' do
    before(:all) do
      @cf = Cashflow.new
      @cf << Transaction.new(-600, date: '1990-01-01'.to_date)
      @cf << Transaction.new(-600, date: '1995-01-01'.to_date)
    end

    it 'is invalid' do
      assert true, !@cf.valid?
    end

    it 'returns 0 instead of exception ' do
      assert_equal BigDecimal.new(0, 6), @cf.xirr
    end


    it 'with a wrong method is invalid' do
      assert_raises(ArgumentError) { @cf.xirr_with_exception(nil, :no_method) }
    end

    it 'raises error when xirr is called' do
      assert_raises(ArgumentError) { @cf.xirr_with_exception }
    end

    it 'raises error when xirr is called' do
      assert true, !@cf.irr_guess
    end

  end

  describe 'an all-positive Cashflow' do
    before(:all) do
      @cf = Cashflow.new
      @cf << Transaction.new(600, date: '1990-01-01'.to_date)
      @cf << Transaction.new(600, date: '1995-01-01'.to_date)
    end

    it 'is invalid' do
      assert true, !@cf.valid?
    end

    it 'raises error when #xirr is called' do
      assert_raises(ArgumentError) { @cf.xirr_with_exception }
    end

    it 'is invalid when #irr_guess is called' do
      assert true, !@cf.irr_guess
    end
  end

  describe 'of a bad investment' do

    before(:all) do
      @cf = Cashflow.new
      @cf << Transaction.new(1000, date: '1985-01-01'.to_date)
      @cf << Transaction.new(-600, date: '1990-01-01'.to_date)
      @cf << Transaction.new(-200, date: '1995-01-01'.to_date)
    end

    it 'has an Internal Rate of Return on Bisection Method' do
      assert_equal '-0.034592'.to_f, @cf.xirr
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert true, @cf.xirr(nil, :newton_method).nan?
    end

    it 'has an educated guess' do
      assert_equal -0.022, @cf.irr_guess
    end

  end

  describe 'of a long investment' do
    before(:all) do
      @cf = Cashflow.new flow: [Transaction.new(-1000, date: Date.new(1957, 1, 1)), Transaction.new(390000, date: Date.new(2013, 1, 1))]
    end

    it 'has an Internal Rate of Return on Bisection Method' do
      assert_equal '0.112339'.to_f, @cf.xirr(nil, :bisection)
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '0.112339'.to_f, @cf.xirr(nil, :newton_method)
    end

    it 'has an educated guess' do
      assert_equal 0.112, @cf.irr_guess.round(6)
    end

  end

  describe 'reapeated cashflow' do
    before(:all) do
      @cf = Cashflow.new
      @cf << Transaction.new(1000.0, date: '2011-12-07'.to_date)
      @cf << Transaction.new(2000.0, date: '2011-12-07'.to_date)
      @cf << Transaction.new(-2000.0, date: '2013-05-21'.to_date)
      @cf << Transaction.new(-4000.0, date: '2013-05-21'.to_date)
    end

    it 'has a compact cashflow' do
      assert_equal 2, @cf.compact_cf.count
    end

    it 'sums all transactions' do
      assert_equal -3000.0, @cf.compact_cf.map(&:amount).inject(&:+)
    end

  end

  describe 'of a real case' do
    before(:all) do
      @cf = Cashflow.new
      @cf << Transaction.new(105187.06, date: '2011-12-07'.to_date)
      @cf << Transaction.new(816709.66, date: '2011-12-07'.to_date)
      @cf << Transaction.new(479069.684, date: '2011-12-07'.to_date)
      @cf << Transaction.new(937309.708, date: '2012-01-18'.to_date)
      @cf << Transaction.new(88622.661, date: '2012-07-03'.to_date)
      @cf << Transaction.new(100000.0, date: '2012-07-03'.to_date)
      @cf << Transaction.new(80000.0, date: '2012-07-19'.to_date)
      @cf << Transaction.new(403627.95, date: '2012-07-23'.to_date)
      @cf << Transaction.new(508117.9, date: '2012-07-23'.to_date)
      @cf << Transaction.new(789706.87, date: '2012-07-23'.to_date)
      @cf << Transaction.new(-88622.661, date: '2012-09-11'.to_date)
      @cf << Transaction.new(-789706.871, date: '2012-09-11'.to_date)
      @cf << Transaction.new(-688117.9, date: '2012-09-11'.to_date)
      @cf << Transaction.new(-403627.95, date: '2012-09-11'.to_date)
      @cf << Transaction.new(403627.95, date: '2012-09-12'.to_date)
      @cf << Transaction.new(789706.871, date: '2012-09-12'.to_date)
      @cf << Transaction.new(88622.661, date: '2012-09-12'.to_date)
      @cf << Transaction.new(688117.9, date: '2012-09-12'.to_date)
      @cf << Transaction.new(45129.14, date: '2013-03-11'.to_date)
      @cf << Transaction.new(26472.08, date: '2013-03-11'.to_date)
      @cf << Transaction.new(51793.2, date: '2013-03-11'.to_date)
      @cf << Transaction.new(126605.59, date: '2013-03-11'.to_date)
      @cf << Transaction.new(278532.29, date: '2013-03-28'.to_date)
      @cf << Transaction.new(99284.1, date: '2013-03-28'.to_date)
      @cf << Transaction.new(58238.57, date: '2013-03-28'.to_date)
      @cf << Transaction.new(113945.03, date: '2013-03-28'.to_date)
      @cf << Transaction.new(405137.88, date: '2013-05-21'.to_date)
      @cf << Transaction.new(-405137.88, date: '2013-05-21'.to_date)
      @cf << Transaction.new(165738.23, date: '2013-05-21'.to_date)
      @cf << Transaction.new(-165738.23, date: '2013-05-21'.to_date)
      @cf << Transaction.new(144413.24, date: '2013-05-21'.to_date)
      @cf << Transaction.new(84710.65, date: '2013-05-21'.to_date)
      @cf << Transaction.new(-84710.65, date: '2013-05-21'.to_date)
      @cf << Transaction.new(-144413.24, date: '2013-05-21'.to_date)

    end

    it 'is a long and bad investment and newton generates an error' do
      assert_equal '-0.99'.to_f, @cf.xirr(nil, :newton_method)
    end

    it 'compacted ' do
      cf = @cf
      cf << Transaction.new(-1000000.0, date: '2013-05-21'.to_date)
      assert_kind_of(Cashflow, cf.compact_cf)
      assert_equal -0.885744, cf.xirr(nil, :newton_method, true)
      assert_equal -0.885744, cf.xirr(nil, :bisection, true)
    end

    it 'has zero for years of investment' do
      cf = Cashflow.new flow: [Transaction.new(105187.06, date: '2011-12-07'.to_date), Transaction.new(-105187.06 * 1.0697668105671994, date: '2011-12-07'.to_date)]
      assert_equal 0.0, cf.irr_guess
      assert_equal Xirr.config.replace_for_nil, cf.xirr(nil, :newton_method)
    end

    it 'has is valid even if compacted' do
      cf = Cashflow.new flow: [Transaction.new(100, date: Date.today), Transaction.new(-100, date: Date.today)]
      assert_equal 0.0, cf.xirr(nil, :newton_method, true)
    end

  end

end
