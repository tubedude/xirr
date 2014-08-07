require_relative 'test_helper'

describe 'Cashflows' do

  describe 'of a good investment' do
    before(:all) do
      @cf = Cashflow.new
      @cf << Transaction.new(1000, date: '1985-01-01'.to_date)
      @cf << Transaction.new(-600, date: '1990-01-01'.to_date)
      @cf << Transaction.new(-6000, date: '1995-01-01'.to_date)
    end

    it 'has an Internal Rate of Return on Bisection Method' do
      assert_equal '0.225683'.to_f, @cf.xirr.round(6)
    end

    it 'has an Internal Rate of Return on Bisection Method using a Guess' do
      assert_equal '0.225683'.to_f, @cf.xirr(0.15).round(6)
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '0.225683'.to_f, @cf.xirr(nil, :newton_method).round(6)
    end

    it 'has an educated guess' do
      assert_equal '0.208'.to_f, @cf.irr_guess.round(6)
    end
  end
  describe 'an invalid array of Transactions' do
    it 'should have an Internal Rate of Return' do
      @cf = Cashflow.new
      @cf << Transaction.new(-600, date: '1990-01-01'.to_date)
      @cf << Transaction.new(-600, date: '1995-01-01'.to_date)
      assert_raises(ArgumentError) { @cf.valid? }
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
      assert_equal '-0.034592'.to_f, @cf.xirr.round(6)
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert true, @cf.xirr(nil, :newton_method).round(6).nan?
    end

    it 'has an educated guess' do
      assert_equal -0.022, @cf.irr_guess.round(6)
    end

  end
  describe 'of a long investment' do
    before(:all) do
      @cf = Cashflow.new
      @cf << Transaction.new(-1000, date: Date.new(1957, 1, 1))
      @cf << Transaction.new(390000, date: Date.new(2013, 1, 1))
    end

    it 'has an Internal Rate of Return on Bisection Method' do
      assert_equal '0.112339'.to_f, @cf.xirr.round(6)
    end

    it 'has an Internal Rate of Return on Newton Method' do
      assert_equal '0.112339'.to_f, @cf.xirr(nil, :newton_method).round(6)
    end

    it 'has an educated guess' do
      assert_equal 0.112, @cf.irr_guess.round(6)
    end

  end

end
