require_relative 'test_helper'

describe 'Xirr::Depreciation' do
  it 'sln — straight line' do
    assert_equal 1800.0, Xirr::Depreciation.sln(10_000, 1_000, 5)
  end

  it 'syd — sum of years digits' do
    assert_equal 3000.0, Xirr::Depreciation.syd(10_000, 1_000, 5, 1)
    assert_equal 600.0, Xirr::Depreciation.syd(10_000, 1_000, 5, 5)
  end

  it 'ddb — double declining balance' do
    assert_equal 4000.0, Xirr::Depreciation.ddb(10_000, 1_000, 5, 1)
    assert_equal 2400.0, Xirr::Depreciation.ddb(10_000, 1_000, 5, 2)
  end

  it 'db — fixed declining balance' do
    assert_in_delta 3690.0, Xirr::Depreciation.db(10_000, 1_000, 5, 1), 1e-2
    assert_in_delta 2328.39, Xirr::Depreciation.db(10_000, 1_000, 5, 2), 1e-2
  end

  it 'rejects a period outside the asset life' do
    assert_raises(ArgumentError) { Xirr::Depreciation.syd(10_000, 1_000, 5, 6) }
  end
end
