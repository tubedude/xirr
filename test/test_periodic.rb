require_relative 'test_helper'

describe 'Periodic (dateless) functions' do
  describe 'Xirr.irr' do
    it 'solves a simple two-period flow' do
      assert_in_delta 0.1, Xirr.irr([-1000, 1100]), 1e-6
    end

    it 'solves a multi-period flow' do
      assert_in_delta 0.156579, Xirr.irr([-1000, 500, 500, 300]), 1e-6
    end

    it 'agrees with npv at the root' do
      rate = Xirr.irr([-1000, 500, 500, 300])
      # The rate is rounded to config.precision, so npv lands near — not exactly — zero.
      assert_in_delta 0.0, Xirr.npv(rate, [-1000, 500, 500, 300]), 1e-3
    end

    it 'raises without both a positive and a negative amount' do
      assert_raises(ArgumentError) { Xirr.irr([-1000, -500]) }
      assert_raises(ArgumentError) { Xirr.irr([1000, 500]) }
    end
  end

  describe 'Xirr.npv' do
    it 'leaves the first amount at period 0' do
      assert_equal 0.0, Xirr.npv(0.1, [-1000, 1100])
    end

    it 'discounts later amounts' do
      assert_in_delta 41.322314, Xirr.npv(0.1, [-1000, 600, 600]), 1e-6
    end
  end

  describe 'Xirr.mirr' do
    it 'matches the closed form' do
      amounts = [-120_000, 39_000, 30_000, 21_000, 37_000, 46_000]
      assert_in_delta 0.126094, Xirr.mirr(amounts, 0.10, 0.12), 1e-6
    end

    it 'raises without both a positive and a negative amount' do
      assert_raises(ArgumentError) { Xirr.mirr([-1, -2], 0.1, 0.1) }
    end
  end
end
