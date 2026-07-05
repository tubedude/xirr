require_relative 'test_helper'

describe 'Xirr::Rates' do
  it 'effective_annual_rate' do
    assert_in_delta 0.104713, Xirr::Rates.effective_annual_rate(0.10, 12), 1e-6
  end

  it 'nominal_rate is the inverse of effective_annual_rate' do
    ear = Xirr::Rates.effective_annual_rate(0.10, 12)
    assert_in_delta 0.1, Xirr::Rates.nominal_rate(ear, 12), 1e-10
  end

  it 'continuous_to_periodic' do
    assert_in_delta 0.105171, Xirr::Rates.continuous_to_periodic(0.10, 1), 1e-6
  end

  it 'rejects a non-positive compounding frequency' do
    assert_raises(ArgumentError) { Xirr::Rates.effective_annual_rate(0.10, 0) }
  end
end
