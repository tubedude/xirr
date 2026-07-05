require_relative 'test_helper'

describe 'Xirr::Brent solver' do
  def cf(*pairs)
    c = Cashflow.new
    pairs.each { |amount, date| c << Transaction.new(amount, date: date.to_date) }
    c
  end

  it 'matches known XIRR values' do
    ok = cf([1000, '1985-01-01'], [-600, '1990-01-01'], [-6000, '1995-01-01'])
    assert_equal '0.225683'.to_f, ok.xirr(method: :brent)

    long = Cashflow.new(flow: [
      Transaction.new(-1000, date: Date.new(1957, 1, 1)),
      Transaction.new(390_000, date: Date.new(2013, 1, 1))
    ])
    assert_equal '0.112339'.to_f, long.xirr(method: :brent)
  end

  it 'handles high rates and near -100% returns' do
    high = cf([1_000_000, '2020-01-01'], [-2_200_000, '2020-05-01'], [-800_000, '2020-06-01'])
    assert_in_delta 21.66094, high.xirr(method: :brent).to_f, 1e-4

    near1 = cf([-10_000, '2014-04-15'], [305.6, '2014-05-15'], [500, '2014-10-19'])
    assert_in_delta(-0.996815, near1.xirr(method: :brent).to_f, 1e-5)
  end

  it 'agrees with rtsafe across random cashflows' do
    rng = Random.new(0xB6E17)
    base = Date.new(2000, 1, 1)
    checked = 0
    100.times do
      c = Cashflow.new
      c << Transaction.new(-(1_000 + rng.rand(9_000)), date: base)
      n = 1 + rng.rand(8)
      (1..n).each { |i| c << Transaction.new(rng.rand(3_000) - 700, date: base + i * (30 + rng.rand(300))) }
      c << Transaction.new(500 + rng.rand(6_000), date: base + (n + 1) * 400)
      next unless c.valid?

      # Different algorithms can land on opposite sides of the last rounded digit,
      # so agree to within a rounding step rather than bit-for-bit.
      assert_in_delta c.xirr(method: :rtsafe).to_f, c.xirr(method: :brent).to_f, 1e-5
      checked += 1
    end
    assert checked > 50, "only #{checked} cases checked"
  end
end
