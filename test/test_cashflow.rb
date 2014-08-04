require_relative 'test_helper'

describe 'Cashflows' do

  describe 'an array of Transactions' do
    before(:all) do
      @xactions = Cashflow.new
      @xactions << Transaction.new( 1000, date: '1985-01-01'.to_time(:utc))
      @xactions << Transaction.new( -600, date: '1990-01-01'.to_time(:utc))
      @xactions << Transaction.new(-6000, date: '1995-01-01'.to_time(:utc))
    end

    it 'haves an Internal Rate of Return' do
      assert_equal '0.225683'.to_f, @xactions.xirr.round(6)
    end

    it 'has an educated guess' do
      assert_equal '0.196'.to_f, @xactions.irr_guess.round(6)
    end

    describe 'an invalid array of Transactions' do
      it 'should have an Internal Rate of Return' do
        @xactions = Cashflow.new
        @xactions << Transaction.new(-600, date: '1990-01-01'.to_time(:utc))
        @xactions << Transaction.new(-600, date: '1995-01-01'.to_time(:utc))
        assert_raises(ArgumentError) { @xactions.valid? }
      end
    end

  end

end
