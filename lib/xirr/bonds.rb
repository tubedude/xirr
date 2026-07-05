# frozen_string_literal: true

module Xirr
  # Fixed income: pricing a bond, solving for its yield, and the standard risk
  # metrics (Macaulay and modified duration, convexity).
  #
  # A bond pays a coupon of +coupon_rate+ a year, split across +freq+ payments
  # (semiannual by default), and returns its +face+ value at maturity, +years+
  # from now. Rates are quoted per year; +ytm+ is the yield to maturity.
  # Settlement is assumed to fall on a coupon date, so prices are clean and the
  # number of coupon periods is whole.
  #
  # The risk metrics don't depend on the face value (it cancels out), so they
  # omit it and lead with +coupon_rate+, unlike {price} and {ytm}.
  module Bonds
    module_function

    # Price of a bond: the present value of its coupons and face value discounted
    # at the yield +ytm+. Prices at par when the coupon rate equals the yield.
    # @return [Float]
    def price(face, coupon_rate, ytm, years, freq = 2, precision: Xirr.config.precision)
      n = periods(years, freq)
      value = RtSafe.present_value(bond_flows(face, coupon_rate, n, freq), ytm.to_f / freq)
      round_value(value, precision)
    end

    # Yield to maturity: the annual yield that discounts a bond's coupons and
    # face value back to +price+. The inverse of {price}; reuses the {RtSafe}
    # solver.
    # @return [Float]
    def ytm(face, coupon_rate, price, years, freq = 2, guess: 0.05, precision: Xirr.config.precision)
      n = periods(years, freq)
      flows = [[0.0, -price * 1.0]] + bond_flows(face, coupon_rate, n, freq)
      periodic = RtSafe.find(flows, guess: guess)
      raise ArgumentError, 'ytm did not converge' if periodic.nil?

      round_value(periodic * freq, precision)
    end

    # Macaulay duration — the present-value-weighted average time, in years,
    # until a bond's cash flows are received.
    # @return [Float]
    def duration(coupon_rate, ytm, years, freq = 2, precision: Xirr.config.precision)
      with_metric(coupon_rate, years, freq, precision) do |flows|
        macaulay(flows, ytm.to_f / freq, freq)
      end
    end

    # Modified duration — Macaulay duration divided by +1 + ytm/freq+. Estimates
    # the percentage price change for a small change in yield.
    # @return [Float]
    def modified_duration(coupon_rate, ytm, years, freq = 2, precision: Xirr.config.precision)
      with_metric(coupon_rate, years, freq, precision) do |flows|
        macaulay(flows, ytm.to_f / freq, freq) / (1 + ytm.to_f / freq)
      end
    end

    # Convexity, in years² — the second-order sensitivity of a bond's price to
    # yield. Pairs with modified duration to refine a price-change estimate.
    # @return [Float]
    def convexity(coupon_rate, ytm, years, freq = 2, precision: Xirr.config.precision)
      with_metric(coupon_rate, years, freq, precision) do |flows|
        convexity_value(flows, ytm.to_f / freq, freq)
      end
    end

    # --- helpers ------------------------------------------------------------

    def round_value(value, precision)
      value.round(precision) + 0.0
    end

    # Validate periods, build unit-face flows, apply +block+, and round.
    def with_metric(coupon_rate, years, freq, precision)
      flows = bond_flows(1, coupon_rate, periods(years, freq), freq)
      round_value(yield(flows), precision)
    end

    # Whole, positive coupon-period count.
    def periods(years, freq)
      n = years * freq
      t = n.to_i
      raise ArgumentError, 'years * freq must be a positive whole number' unless freq > 0 && n == t && t.positive?

      t
    end

    # Coupon + redemption flows on +face+ as [[period, amount]], k = 1..n; the
    # face value is added onto the final coupon.
    def bond_flows(face, coupon_rate, n, freq)
      coupon = face * coupon_rate / freq
      (1..n).map do |k|
        amount = k == n ? coupon + face : coupon
        [k * 1.0, amount * 1.0]
      end
    end

    def weighted_pv(flows, rate)
      flows.map { |k, cf| [k, cf / (1 + rate)**k] }
    end

    # Macaulay duration in years: PV-weighted average period, divided by freq.
    def macaulay(flows, rate, freq)
      weighted = weighted_pv(flows, rate)
      price = weighted.sum { |_k, pv| pv }
      weighted.sum { |k, pv| k * pv } / price / freq
    end

    # Convexity in years²: the k·(k+1)-weighted PV sum, annualized by freq².
    def convexity_value(flows, rate, freq)
      weighted = weighted_pv(flows, rate)
      price = weighted.sum { |_k, pv| pv }
      num = weighted.sum { |k, pv| k * (k + 1) * pv }
      num / price / (1 + rate)**2 / freq**2
    end

    private_class_method :round_value, :with_metric, :periods, :bond_flows,
                         :weighted_pv, :macaulay, :convexity_value
  end
end
