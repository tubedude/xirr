# frozen_string_literal: true

module Xirr
  # Performance and risk metrics: {volatility}, {cagr}, {payback_period},
  # {discounted_payback_period}, {profitability_index}, and {twr}.
  #
  # The cash-flow functions follow the same convention as {Xirr.npv}: the initial
  # outlay sits at index 0 (undiscounted) and later flows fall at periods 1, 2, ….
  module Returns
    module_function

    # Annualised volatility of a price series — the sample standard deviation of
    # its period-over-period returns, scaled up by +√periods_per_year+. Needs at
    # least three positive prices, in time order.
    # @param returns [:simple, :log] how to measure each return: +(b-a)/a+ or +ln(b/a)+
    # @return [Float]
    def volatility(prices, periods_per_year: 252, returns: :simple, precision: Xirr.config.precision)
      rets = period_returns(prices, returns)
      raise ArgumentError, 'need at least three prices' if rets.length < 2

      round_value(annualise(rets, periods_per_year), precision)
    end

    # Compound annual growth rate — the constant yearly rate that grows
    # +begin_value+ into +end_value+ over +years+.
    # @return [Float]
    def cagr(begin_value, end_value, years, precision: Xirr.config.precision)
      if begin_value <= 0 || years <= 0 || end_value.to_f / begin_value < 0
        raise ArgumentError, 'undefined'
      end

      round_value((end_value.to_f / begin_value)**(1.0 / years) - 1, precision)
    end

    # Payback period — how many periods of cash flow it takes to recover the
    # initial outlay, interpolating within the recovering period. The first
    # amount is the outlay (negative), the rest are inflows.
    # @return [Float]
    def payback_period(cash_flows, precision: Xirr.config.precision)
      recovery(cash_flows, precision)
    end

    # Like {payback_period}, but recovers the outlay from cash flows discounted
    # at +rate+, so it accounts for the time value of money.
    # @return [Float]
    def discounted_payback_period(cash_flows, rate, precision: Xirr.config.precision)
      recovery(discount_flows(cash_flows, rate), precision)
    end

    # Profitability index — the present value of future inflows per unit of
    # initial investment, discounted at +rate+. Above 1 means the project adds
    # value. Equivalent to +1 + NPV / initial investment+.
    # @return [Float]
    def profitability_index(cash_flows, rate, precision: Xirr.config.precision)
      raise ArgumentError, 'need at least one flow' if cash_flows.empty?
      raise ArgumentError, 'the first flow must be an outlay (negative)' if cash_flows.first >= 0

      npv = Xirr.npv(rate, cash_flows)
      round_value(1 + npv / -cash_flows.first, precision)
    end

    # Time-weighted return — period returns linked geometrically,
    # +∏(1 + rᵢ) − 1+. Immune to the timing of cash flows. Pass
    # +periods_per_year+ to annualise.
    # @return [Float]
    def twr(period_returns, periods_per_year: nil, precision: Xirr.config.precision)
      raise ArgumentError, 'need at least one return' if period_returns.empty?
      raise ArgumentError, 'returns must be numbers' unless period_returns.all? { |r| r.is_a?(Numeric) }

      round_value(time_weighted(period_returns, periods_per_year), precision)
    end

    # --- helpers ------------------------------------------------------------

    def round_value(value, precision)
      value.round(precision) + 0.0
    end

    # Consecutive-pair returns. Raises if a price is non-numeric or non-positive.
    def period_returns(prices, kind)
      prices.each_cons(2).map do |a, b|
        raise ArgumentError, 'prices must be numbers' unless a.is_a?(Numeric) && b.is_a?(Numeric)
        raise ArgumentError, 'every price must be positive' unless a.positive? && b.positive?

        kind == :log ? Math.log(b.to_f / a) : (b - a).to_f / a
      end
    end

    def annualise(returns, periods_per_year)
      n = returns.length
      mean = returns.sum / n.to_f
      sum_of_squares = returns.sum { |r| (r - mean)**2 }
      Math.sqrt(sum_of_squares / (n - 1)) * Math.sqrt(periods_per_year)
    end

    def recovery(flows, precision)
      whole, shortfall, recovering_flow = cumulative_recovery(flows)
      round_value(whole + shortfall / recovering_flow, precision)
    end

    # Find the first period where the running cumulative crosses from negative to
    # non-negative. Raises when it never crosses or there are no flows.
    def cumulative_recovery(flows)
      raise ArgumentError, 'need at least one flow' if flows.empty?

      cumulative = 0.0
      flows.each_with_index do |flow, i|
        nxt = cumulative + flow
        return [i - 1, -cumulative, flow] if i.positive? && cumulative.negative? && nxt >= 0

        cumulative = nxt
      end
      raise ArgumentError, 'the outlay is never recovered'
    end

    def discount_flows(flows, rate)
      flows.each_with_index.map { |flow, i| flow / (1 + rate)**i }
    end

    def time_weighted(returns, periods_per_year)
      cumulative = returns.reduce(1.0) { |acc, r| acc * (1 + r) } - 1
      return cumulative if periods_per_year.nil?

      (1 + cumulative)**(periods_per_year.to_f / returns.length) - 1
    end

    private_class_method :round_value, :period_returns, :annualise, :recovery,
                         :cumulative_recovery, :discount_flows, :time_weighted
  end
end
