# frozen_string_literal: true

module Xirr
  # Shared numerics for the solver classes: the net present value of a cashflow,
  # its derivative, and the discounting timeline. Each solver includes this and
  # is constructed with the {Cashflow} it works on.
  module Base
    attr_reader :cf

    # @param cf [Cashflow] the cashflow to solve
    def initialize(cf)
      @cf = cf
    end

    # Periods (years, with the default period) from the first transaction to +date+.
    # @param date [Date]
    # @return [Float]
    def periods_from_start(date)
      (date - cf.min_date) / cf.period
    end

    # Net present value of the cashflow at +rate+: Σ amount / (1 + rate)^t.
    # @param rate [Float]
    # @return [Float]
    def xnpv(rate)
      r = rate.to_f
      flows.inject(0.0) { |sum, (t, amount)| sum + amount / (1 + r)**t }
    end

    # Derivative of {#xnpv} with respect to rate: Σ -t · amount / (1 + rate)^(t+1).
    # @param rate [Float]
    # @return [Float]
    def xnpv_derivative(rate)
      r = rate.to_f
      flows.inject(0.0) { |sum, (t, amount)| sum + (-t * amount / (1 + r)**(t + 1)) }
    end

    private

    # The cashflow as [years_from_start, amount] pairs, built once per solve so
    # the date arithmetic isn't repeated on every NPV evaluation.
    # @return [Array<Array(Float, Float)>]
    def flows
      @flows ||= cf.map { |t| [periods_from_start(t.date).to_f, t.amount.to_f] }
    end
  end
end
