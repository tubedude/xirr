# frozen_string_literal: true

module Xirr
  # Periodic (dateless) cash-flow functions. Where {Cashflow} works with dated
  # flows, these take a plain list of amounts landing at equally spaced periods
  # 0, 1, 2, …, for when the exact dates don't matter. The rate they return is
  # per period.
  module_function

  # Internal rate of return of +amounts+ at periods 0, 1, 2, …
  #
  #   Xirr.irr([-1000, 1100])         # => 0.1
  #   Xirr.irr([-1000, 500, 500, 300]) # => 0.156579
  #
  # @param amounts [Array<Numeric>]
  # @param guess [Float] initial rate for the solver
  # @return [Float] the rate per period
  # @raise [ArgumentError] when there aren't at least one inflow and one outflow
  def irr(amounts, guess: 0.1)
    flows = validated_flows(amounts)
    rate = RtSafe.find(flows, guess: guess)
    raise ArgumentError, 'IRR did not converge' if rate.nil?
    rate
  end

  # Net present value of +amounts+ at periods 0, 1, 2, … discounted at +rate+.
  # The first amount sits at period 0 and is left undiscounted, so
  # +Xirr.npv(Xirr.irr(a), a)+ comes out to roughly zero. This differs from a
  # spreadsheet +NPV+, which places the first amount at period 1.
  #
  #   Xirr.npv(0.1, [-1000, 1100])      # => 0.0
  #   Xirr.npv(0.1, [-1000, 600, 600])  # => 41.322314
  #
  # @param rate [Numeric]
  # @param amounts [Array<Numeric>]
  # @return [Float]
  def npv(rate, amounts)
    amounts.each_with_index.inject(0.0) do |sum, (amount, i)|
      sum + amount.to_f / (1.0 + rate) ** i
    end.round(Xirr.config.precision)
  end

  # Modified internal rate of return of periodic +amounts+. Positive flows are
  # assumed reinvested at +reinvest_rate+, negative flows financed at
  # +finance_rate+.
  #
  #   Xirr.mirr([-120_000, 39_000, 30_000, 21_000, 37_000, 46_000], 0.10, 0.12)
  #   # => 0.126094
  #
  # @param amounts [Array<Numeric>]
  # @param finance_rate [Numeric]
  # @param reinvest_rate [Numeric]
  # @return [Float]
  def mirr(amounts, finance_rate, reinvest_rate)
    values = validated_amounts(amounts)
    periods = values.length - 1

    future_of_inflows = values.each_with_index.inject(0.0) do |acc, (value, i)|
      value > 0 ? acc + value * (1.0 + reinvest_rate) ** (periods - i) : acc
    end
    present_of_outflows = values.each_with_index.inject(0.0) do |acc, (value, i)|
      value < 0 ? acc + value / (1.0 + finance_rate) ** i : acc
    end

    ((future_of_inflows / -present_of_outflows) ** (1.0 / periods) - 1).round(Xirr.config.precision)
  end

  # @api private
  def validated_amounts(amounts)
    values = amounts.map(&:to_f)
    raise ArgumentError, 'Need at least two amounts' if values.length < 2
    unless values.any?(&:positive?) && values.any?(&:negative?)
      raise ArgumentError, 'Need at least one positive and one negative amount'
    end
    values
  end

  # @api private
  def validated_flows(amounts)
    validated_amounts(amounts).each_with_index.map { |amount, i| [i.to_f, amount] }
  end

  private_class_method :validated_amounts, :validated_flows
end
