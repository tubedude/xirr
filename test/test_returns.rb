require_relative 'test_helper'

describe 'Xirr::Returns' do
  it 'volatility — annualised' do
    assert_in_delta 0.234528, Xirr::Returns.volatility([100, 102, 101, 103, 105]), 1e-6
  end

  it 'cagr — compound annual growth rate' do
    assert_in_delta 0.071773, Xirr::Returns.cagr(1000, 2000, 10), 1e-6
  end

  it 'payback_period' do
    assert_equal 2.5, Xirr::Returns.payback_period([-1000, 400, 400, 400])
  end

  it 'discounted_payback_period' do
    assert_in_delta 1.916667, Xirr::Returns.discounted_payback_period([-1000, 600, 600, 600], 0.1), 1e-6
  end

  it 'profitability_index' do
    assert_in_delta 1.041322, Xirr::Returns.profitability_index([-1000, 600, 600], 0.1), 1e-6
  end

  it 'twr — cumulative' do
    assert_in_delta 0.1286, Xirr::Returns.twr([0.10, -0.05, 0.08]), 1e-6
  end

  it 'twr — annualised' do
    assert_in_delta 0.082432, Xirr::Returns.twr([0.02, 0.02], periods_per_year: 4), 1e-6
  end

  it 'raises when the outlay is never recovered' do
    assert_raises(ArgumentError) { Xirr::Returns.payback_period([-1000, 100, 100]) }
  end
end
