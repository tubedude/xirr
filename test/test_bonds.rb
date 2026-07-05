require_relative 'test_helper'

describe 'Xirr::Bonds' do
  it 'price — at par when coupon equals yield' do
    assert_equal 100.0, Xirr::Bonds.price(100, 0.05, 0.05, 10)
  end

  it 'price — at a discount when yield exceeds coupon' do
    assert_in_delta 875.377897, Xirr::Bonds.price(1000, 0.08, 0.10, 10), 1e-6
  end

  it 'ytm is the inverse of price' do
    assert_in_delta 0.1, Xirr::Bonds.ytm(1000, 0.08, 875.377897, 10), 1e-6
  end

  it 'duration — Macaulay' do
    assert_equal 10.0, Xirr::Bonds.duration(0.0, 0.05, 10, 1)
    assert_in_delta 2.833393, Xirr::Bonds.duration(0.06, 0.06, 3, 1), 1e-6
  end

  it 'modified_duration' do
    assert_in_delta 9.52381, Xirr::Bonds.modified_duration(0.0, 0.05, 10, 1), 1e-5
    assert_in_delta 2.673012, Xirr::Bonds.modified_duration(0.06, 0.06, 3, 1), 1e-6
  end

  it 'convexity' do
    assert_in_delta 99.773243, Xirr::Bonds.convexity(0.0, 0.05, 10, 1), 1e-6
    assert_in_delta 9.891032, Xirr::Bonds.convexity(0.06, 0.06, 3, 1), 1e-6
  end

  it 'rejects a degenerate period count' do
    assert_raises(ArgumentError) { Xirr::Bonds.price(100, 0.05, 0.05, 0) }
  end
end
