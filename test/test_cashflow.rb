require_relative 'test_helper'

describe 'Cashflows' do

  describe 'of a ok investment' do
    before(:all) do
      @cf = Cashflow.new
      @cf << Transaction.new(1000, date: '1985-01-01'.to_date)
      @cf << Transaction.new(-600, date: '1990-01-01'.to_date)
      @cf << Transaction.new(-6000, date: '1995-01-01'.to_date)
    end

    it 'with a wrong method is invalid' do
      assert_raises(ArgumentError) { @cf.xirr(nil, :no_method) }
    end

    it 'has an Internal Rate of Return on default Method' do
      assert_equal '0.225683'.to_f, @cf.xirr
    end

    it 'has an Internal Rate of Return on default Method' do
      assert_equal '0.225683'.to_f, @cf.xirr(nil, :bisection)
    end

    it 'has an Internal Rate of Return on Bisection Method using a Guess' do
      assert_equal '0.225683'.to_f, @cf.xirr(0.15)
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

    it 'has an Internal Rate of Return on Bisection Method' do
      assert_equal '0.225683'.to_f, @cf.xirr
    end

    it 'has an Internal Rate of Return on Bisection Method using a Guess' do
      assert_equal '0.225683'.to_f, @cf.xirr(0.15)
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '0.225683'.to_f, @cf.xirr(nil, :newton_method)
    end

    it 'has an educated guess' do
      assert_equal '0.208'.to_f, @cf.irr_guess
    end
  end

  describe 'of a good investment' do
    before(:all) do
      @cf = Cashflow.new
      @cf << Transaction.new(1000, date: '1985-01-01'.to_date)
      @cf << Transaction.new(-6000, date: '1985-01-02'.to_date)
    end

    it 'has an Internal Rate of Return on Bisection Method' do
      assert_equal '1.0597572345993451e+284'.to_f, @cf.xirr
    end

    it 'has an Internal Rate of Return on Bisection Method using a bad Guess' do
      assert_raises(ArgumentError) { @cf.xirr(0.15) }
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

    it 'returns 0 instead of expection ' do
      assert_equal BigDecimal.new(0, 6), @cf.xirr_no_exception
    end


    it 'with a wrong method is invalid' do
      assert_raises(ArgumentError) { @cf.xirr(nil, :no_method) }
    end

    it 'raises error when xirr is called' do
      assert_raises(ArgumentError) { @cf.xirr }
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

    it 'raises error when xirr is called' do
      assert_raises(ArgumentError) { @cf.xirr }
    end

    it 'raises error when xirr is called' do
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
      @cf = Cashflow.new
      @cf << Transaction.new(-1000, date: Date.new(1957, 1, 1))
      @cf << Transaction.new(390000, date: Date.new(2013, 1, 1))
    end

    it 'has an Internal Rate of Return on Bisection Method' do
      assert_equal '0.112339'.to_f, @cf.xirr
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '0.112339'.to_f, @cf.xirr(nil, :newton_method)
    end

    it 'has an educated guess' do
      assert_equal 0.112, @cf.irr_guess.round(6)
    end

  end

end
