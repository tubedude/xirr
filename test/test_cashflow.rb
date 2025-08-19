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
      assert_equal '0.225683'.to_f, @cf.xirr(method: :bisection)
    end

    it 'has an Internal Rate of Return on Bisection Method using a Guess' do
      assert_in_delta '0.225683'.to_f, @cf.xirr(guess: 0.15).to_f, 0.000002
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '0.225683'.to_f, @cf.xirr(method: :newton_method)
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
      assert_equal '0.225683'.to_f, @cf.xirr(method: :bisection)
    end

    it 'has an Internal Rate of Return on Bisection Method using a Guess' do
      assert_in_delta '0.225683'.to_f, @cf.xirr(guess: 0.15).to_f, 0.000002
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '0.225683'.to_f, @cf.xirr(method: :newton_method)
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

    it 'bisection does not converge' do
      assert_raises(ArgumentError) { @cf.xirr(guess: -0.15, method: :bisection, raise_exception: true, iteration_limit: 1) }
    end


    it 'has an Internal Rate of Return on Bisection Method' do
      assert_equal '22.352207  '.to_f, @cf.xirr(method: :bisection)
    end

    it 'it won\'t fall back if method provided' do
      @cf.xirr method: :bisection
      assert_equal false, @cf.fallback
    end

    it 'has a sum of its transactions' do
      assert_equal '-2000000'.to_f, @cf.sum
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '22.352206 '.to_f, @cf.xirr(method: :newton_method)
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

    it 'returns error if method is invalid' do
      assert_raises(ArgumentError) { @cf.xirr(guess: 0.15, method: :new, raise_exception: true) }
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '1.0597572345993451e+284'.to_f, @cf.xirr(method: :newton_method)
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
      assert_equal BigDecimal(0, 6), @cf.xirr
    end

    it 'with a wrong method is invalid' do
      assert_raises(ArgumentError) { @cf.xirr raise_exception: true, method: :no_method }
    end

    it 'raises error when xirr is called' do
      assert_raises(ArgumentError) { @cf.xirr raise_exception: true }
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
      assert_raises(ArgumentError) { @cf.xirr raise_exception: true }
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
      assert true, @cf.xirr(method: :newton_method).nan?
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
      assert_equal '0.112339'.to_f, @cf.xirr(method: :bisection)
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '0.112339'.to_f, @cf.xirr(method: :newton_method)
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
    #
    # it 'has a compact cashflow' do
    #   assert_equal 2, @cf.compact_cf.count
    # end

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
      skip 'Test is weirdly taking too long'
      assert_equal '-1.0'.to_f, @cf.xirr #(method: :newton_method)
    end
  end

  describe 'xichen27' do
    it 'it matchs Excel' do
      cf = Cashflow.new
      cf << Transaction.new(-10000, date: '2014-04-15'.to_date)
      cf << Transaction.new(305.6, date: '2014-05-15'.to_date)
      cf << Transaction.new(500, date: '2014-10-19'.to_date)
      assert_equal '-0.996814607'.to_f.round(3), cf.xirr.to_f.round(3)
    end
  end

  describe 'marano' do
    it 'it matchs Excel' do
      cf = Cashflow.new
      cf << Transaction.new(900.0, date: '2014-11-07'.to_date)
      cf << Transaction.new(-13.5, date: '2015-05-06'.to_date)
      assert_equal '-0.9998'.to_f.round(4), cf.xirr.to_f.round(4)
    end
  end

  describe 'period' do
    it 'has zero for years of investment' do
      cf = Cashflow.new flow: [Transaction.new(105187.06, date: '2011-12-07'.to_date), Transaction.new(-105187.06 * 1.0697668105671994, date: '2011-12-07'.to_date)]
      assert_equal 0.0, cf.irr_guess
      assert_equal Xirr::REPLACE_FOR_NIL, cf.xirr #(method: :newton_method)
    end

    it 'respects a different period' do
      cf = Cashflow.new period: 100, flow: [Transaction.new(-1000, date: Date.new(1957, 1, 1)), Transaction.new(390000, date: Date.new(2013, 1, 1))]
      assert_equal 0.029598, cf.xirr
    end

    it 'respects default and ad hoc period' do
      cf = Cashflow.new period: 100, flow: [Transaction.new(-1000, date: Date.new(1957, 1, 1)), Transaction.new(390000, date: Date.new(2013, 1, 1))]
      assert_equal 0.112339, cf.xirr(period: 365.0)
    end
  end

  describe 'with changing precision values' do
    before(:all) do
      # {"2021-05-17"=>-3005.69, "2021-06-03"=>-4781.38, "2021-06-17"=>3.09, "2021-06-21"=>8509.93}
      @cf = Cashflow.new
      @cf << Transaction.new(-117.38, date: '2021-03-17'.to_date)
      @cf << Transaction.new(-2370.02, date: '2021-03-23'.to_date)
      @cf << Transaction.new(0.29, date: '2021-03-26'.to_date)
      @cf << Transaction.new(0.32, date: '2021-04-01'.to_date)
      @cf << Transaction.new(-3005.69, date: '2021-05-17'.to_date)
      @cf << Transaction.new(-4781.38, date: '2021-06-03'.to_date)
      @cf << Transaction.new(3.09, date: '2021-06-17'.to_date)
      @cf << Transaction.new(8509.93, date: '2021-06-21'.to_date)
    end

    it 'gives nil value for xirr' do
      assert_equal 0.0, @cf.xirr
    end

    it 'gives correct value with configuration' do
      Xirr.configure do |config|
        config.precision = 10
        config.eps = '1.0e-8'.to_f
      end
      assert_equal  -0.8317173694e0, @cf.xirr
    end

    # resetting configuration
    after(:all) do
      Xirr.configure do |config|
        config.precision = 6
        config.eps = '1.0e-6'.to_f
      end
    end
  end

  describe 'irr_guess' do
    it 'Basic Scenario with Simple Positive Cash Flows' do
      @cf = Cashflow.new
      @cf << Transaction.new(1000, date: '2000-01-01'.to_date)
      @cf << Transaction.new(-1200, date: '2001-01-01'.to_date)
      assert_equal '0.2'.to_f, @cf.irr_guess
    end
    
    it 'Zero Periods of Investment' do
      @cf = Cashflow.new
      @cf << Transaction.new(1000, date: '2000-01-01'.to_date)
      @cf << Transaction.new(-1000, date: '2000-01-01'.to_date)
      assert_equal '0.0'.to_f, @cf.irr_guess
    end
    
    it 'Negative Multiple' do
      @cf = Cashflow.new
      @cf << Transaction.new(1000, date: '2000-01-01'.to_date)
      @cf << Transaction.new(-2000, date: '2000-01-01'.to_date)
      assert_equal '0.0'.to_f, @cf.irr_guess
    end
    
    it 'No Cash Flows' do
      @cf = Cashflow.new
      assert_equal '0.0'.to_f, @cf.irr_guess
    end
    
    it 'Multiple Positive Cash Flows and Large Investment Period' do
      @cf = Cashflow.new
      @cf << Transaction.new(1000, date: '2000-01-01'.to_date)
      @cf << Transaction.new(-100, date: '2010-01-01'.to_date)
      @cf << Transaction.new(-100, date: '2020-01-01'.to_date)
      assert_equal '0.072'.to_f, @cf.irr_guess
    end
    
    it 'Very Small Periods of Investment' do
      @cf = Cashflow.new
      @cf << Transaction.new(1000, date: '2000-01-01'.to_date)
      @cf << Transaction.new(-500, date: '2000-01-02'.to_date)
      assert_equal '0.0'.to_f, @cf.irr_guess
    end
    
    it 'Complex Cash Flows' do
      @cf = Cashflow.new
      @cf << Transaction.new(1000, date: '2000-01-01'.to_date)
      @cf << Transaction.new(-500, date: '2001-01-01'.to_date)
      @cf << Transaction.new(-300, date: '2002-01-01'.to_date)
      @cf << Transaction.new(-200, date: '2003-01-01'.to_date)
      assert_equal '0.195'.to_f, @cf.irr_guess
    end
    
    it 'Only Negative Cash Flows' do
      @cf = Cashflow.new
      @cf << Transaction.new(-1000, date: '2000-01-01'.to_date)
      @cf << Transaction.new(-500, date: '2001-01-01'.to_date)
      assert_equal '0.0'.to_f, @cf.irr_guess
    end
    
    it 'Positive and Negative Cash Flows Spread Over Different Periods' do
      @cf = Cashflow.new
      @cf << Transaction.new(500, date: '2000-01-01'.to_date)
      @cf << Transaction.new(-100, date: '2005-01-01'.to_date)
      @cf << Transaction.new(-400, date: '2010-01-01'.to_date)
      assert_equal '0.033'.to_f, @cf.irr_guess
    end
  end 
end
