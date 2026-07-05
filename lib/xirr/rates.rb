# frozen_string_literal: true

module Xirr
  # Converting between the ways an interest rate can be quoted. A nominal rate
  # paired with a compounding frequency, the effective annual rate it actually
  # earns, and a continuously-compounded rate all describe the same return in
  # different terms; these move between them.
  module Rates
    module_function

    # Effective annual rate earned by a +nominal+ rate compounded +m+ times a
    # year: +(1 + nominal/m)^m − 1+.
    # @return [Float]
    def effective_annual_rate(nominal, m)
      raise ArgumentError, 'm must be positive' if m <= 0

      (1 + nominal / m)**m - 1
    end

    # Nominal rate that, compounded +m+ times a year, produces the +effective+
    # annual rate. The inverse of {effective_annual_rate}.
    # @return [Float]
    def nominal_rate(effective, m)
      raise ArgumentError, 'm must be positive' if m <= 0
      raise ArgumentError, 'effective must be above -100%' if 1 + effective <= 0

      m * ((1 + effective)**(1.0 / m) - 1)
    end

    # Per-period rate equivalent to a continuously-compounded annual +rate+, for
    # +periods+ periods a year: +e^(rate/periods) − 1+.
    # @return [Float]
    def continuous_to_periodic(rate, periods)
      raise ArgumentError, 'periods must be positive' if periods <= 0

      Math.exp(rate / periods) - 1
    end
  end
end
