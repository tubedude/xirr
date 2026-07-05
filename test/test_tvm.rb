require_relative 'test_helper'

describe 'Xirr::TVM' do
  it 'fv — future value' do
    assert_in_delta 2886.68, Xirr::TVM.fv(0.05, 10, -100, -1000).round(2), 1e-2
  end

  it 'pv — present value' do
    assert_in_delta 1386.09, Xirr::TVM.pv(0.05, 10, -100, -1000).round(2), 1e-2
  end

  it 'pmt — level payment' do
    assert_in_delta(-162.75, Xirr::TVM.pmt(0.10, 10, 1000).round(2), 1e-2)
  end

  it 'ipmt — interest portion' do
    assert_in_delta(-8.333333, Xirr::TVM.ipmt(0.10 / 12, 1, 12, 1000), 1e-6)
  end

  it 'ppmt — principal portion' do
    assert_in_delta(-79.582554, Xirr::TVM.ppmt(0.10 / 12, 1, 12, 1000), 1e-6)
  end

  it 'ipmt + ppmt equals pmt for every period' do
    payment = Xirr::TVM.pmt(0.10 / 12, 12, 1000)
    (1..12).each do |per|
      split = Xirr::TVM.ipmt(0.10 / 12, per, 12, 1000) + Xirr::TVM.ppmt(0.10 / 12, per, 12, 1000)
      assert_in_delta payment, split, 1e-9
    end
  end

  it 'nper — number of periods' do
    assert_in_delta 14.21, Xirr::TVM.nper(0.05, -100, 1000).round(2), 1e-2
  end

  it 'rate — solves for the periodic rate' do
    assert_equal 0.0, Xirr::TVM.rate(10, -100, 1000)
  end

  it 'validates the type argument' do
    assert_raises(ArgumentError) { Xirr::TVM.fv(0.05, 10, -100, -1000, 2) }
  end

  it 'handles annuity due (type 1)' do
    # A due payment is the ordinary payment discounted one period earlier.
    ordinary = Xirr::TVM.pmt(0.10, 10, 1000, 0, 0)
    due = Xirr::TVM.pmt(0.10, 10, 1000, 0, 1)
    assert_in_delta ordinary / 1.10, due, 1e-9
  end

  describe 'amortization_schedule' do
    before do
      @schedule = Xirr::TVM.amortization_schedule(0.10 / 12, 12, 1000)
    end

    it 'has a correct first row' do
      first = @schedule.first
      assert_equal(-87.92, first[:payment])
      assert_equal(-8.33, first[:interest])
      assert_equal(-79.59, first[:principal])
      assert_equal 920.41, first[:balance]
    end

    it 'pays the balance down to exactly zero' do
      assert_equal 0.0, @schedule.last[:balance]
      assert_equal 12, @schedule.length
    end
  end
end
