require_relative 'test_helper'

# Property and stress tests for the rtsafe solver. These are the tests that would
# catch a bracketing or overflow regression: they assert the invariant a solver
# must satisfy — the returned rate sits within one precision-step of a genuine
# sign change of the net present value — rather than a hand-computed number.
describe 'rtsafe solver properties' do
  # The rounding granularity of a converged result.
  H = 10.0**(-Xirr.config.precision)

  # The returned rate is a real root to the configured precision when the NPV
  # changes sign across [rate - H, rate + H] (or is already ~0 there). This holds
  # regardless of the flow's magnitude or maturity, so it doubles as the property
  # assertion and the stress-case assertion.
  def assert_root(cf, rate)
    here = cf.xnpv(rate)
    lo   = cf.xnpv(rate - H)
    hi   = cf.xnpv(rate + H)
    straddles = (lo <= 0 && hi >= 0) || (lo >= 0 && hi <= 0)
    assert straddles || here.abs < 1e-6,
           "rate #{rate} is not a root to precision #{Xirr.config.precision}: " \
           "xnpv(r-H)=#{lo}, xnpv(r)=#{here}, xnpv(r+H)=#{hi}"
  end

  # A valid, single-sign-change cashflow: an initial outlay followed by returns.
  def random_cashflow(rng)
    cf   = Cashflow.new
    base = Date.new(2000, 1, 1)
    cf << Transaction.new(-(1_000 + rng.rand(9_000)), date: base)
    n = 1 + rng.rand(10)
    (1..n).each do |i|
      days = i * (30 + rng.rand(400))
      cf << Transaction.new(rng.rand(3_500) - 800, date: base + days)
    end
    # Guarantee at least one inflow so the series changes sign.
    cf << Transaction.new(500 + rng.rand(6_000), date: base + (n + 1) * 400)
    cf
  end

  it 'returns a genuine root for random cashflows' do
    rng     = Random.new(0xC0FFEE)
    checked = 0
    300.times do
      cf = random_cashflow(rng)
      next unless cf.valid?

      rate =
        begin
          cf.xirr!(method: :rtsafe)
        rescue ArgumentError
          next # genuine non-convergence, nothing to assert about
        end

      assert_root(cf, rate)
      checked += 1
    end
    assert checked > 100, "property test was nearly vacuous: only #{checked} cases checked"
  end

  it 'agrees with bisection and newton on a well-behaved flow' do
    cf = Cashflow.new
    cf << Transaction.new(1000, date: '1985-01-01'.to_date)
    cf << Transaction.new(-600, date: '1990-01-01'.to_date)
    cf << Transaction.new(-6000, date: '1995-01-01'.to_date)
    assert_in_delta cf.xirr(method: :bisection).to_f, cf.xirr(method: :rtsafe).to_f, 1e-5
    assert_in_delta cf.xirr(method: :newton_method).to_f, cf.xirr(method: :rtsafe).to_f, 1e-5
  end

  describe 'stress cases' do
    it 'handles a 30-year monthly schedule (long maturity, low per-period rate)' do
      cf   = Cashflow.new
      base = Date.new(1990, 1, 1)
      cf << Transaction.new(-100_000, date: base)
      360.times { |m| cf << Transaction.new(650, date: base >> (m + 1)) }
      rate = cf.xirr!(method: :rtsafe)
      assert rate > 0, "expected a positive rate, got #{rate}"
      assert_root(cf, rate)
    end

    it 'handles a near -100% return without overflowing' do
      cf = Cashflow.new
      cf << Transaction.new(-10_000, date: '2014-04-15'.to_date)
      cf << Transaction.new(305.6, date: '2014-05-15'.to_date)
      cf << Transaction.new(500, date: '2014-10-19'.to_date)
      rate = cf.xirr!(method: :rtsafe)
      assert rate < -0.9, "expected a rate near -1, got #{rate}"
      assert rate > -1.0
    end

    it 'handles a very long, low-rate horizon' do
      cf = Cashflow.new flow: [
        Transaction.new(-1000, date: Date.new(1957, 1, 1)),
        Transaction.new(390_000, date: Date.new(2013, 1, 1))
      ]
      assert_in_delta 0.112339, cf.xirr!(method: :rtsafe).to_f, 1e-5
    end

    it 'reports non-convergence rather than crashing on an impossible bracket' do
      # One day apart with an enormous return: the root is astronomically high and
      # lies outside any sane bracket, so rtsafe gives up cleanly.
      cf = Cashflow.new
      cf << Transaction.new(1000, date: '1985-01-01'.to_date)
      cf << Transaction.new(-6000, date: '1985-01-02'.to_date)
      assert_raises(ArgumentError) { cf.xirr!(method: :rtsafe) }
    end

    it 'the native rtsafe_c matches the pure-Ruby rtsafe' do
      skip 'native extension not compiled' unless Xirr::NATIVE
      rng = Random.new(0xBEEF)
      50.times do
        cf = random_cashflow(rng)
        next unless cf.valid?
        assert_equal cf.xirr(method: :rtsafe), cf.xirr(method: :rtsafe_c)
      end
    end

    it 'raises a clear error when rtsafe_c is chosen without the extension' do
      skip 'extension is compiled here' if Xirr::NATIVE
      cf = Cashflow.new
      cf << Transaction.new(-1000, date: '2014-01-01'.to_date)
      cf << Transaction.new(1100, date: '2015-01-01'.to_date)
      assert_raises(ArgumentError) { cf.xirr(method: :rtsafe_c) }
    end

    it 'newton does not crash when a guess overshoots below -100%' do
      # A Newton step from this guess drives the rate below -1, where the
      # discount base goes negative; the solver must bail, not raise.
      cf = Cashflow.new
      cf << Transaction.new(-10_000, date: '2014-04-15'.to_date)
      cf << Transaction.new(305.6, date: '2014-05-15'.to_date)
      cf << Transaction.new(500, date: '2014-10-19'.to_date)
      assert_equal Xirr::REPLACE_FOR_NIL, cf.xirr(method: :newton_method, guess: 0.1)
    end
  end
end
