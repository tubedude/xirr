module Xirr

  # Methods that will be included in Cashflow to calculate XIRR
  class Bisection
    include Base

    # Calculates yearly Internal Rate of Return
    # @return [BigDecimal]
    # @param midpoint [Float]
    # An initial guess rate will override the {Cashflow#irr_guess}
    def xirr(midpoint = nil)

      # Initial values
      left = BigDecimal.new -0.99, Xirr::PRECISION
      right = BigDecimal.new 9.99, Xirr::PRECISION
      midpoint ||= cf.irr_guess
      limit = Xirr.config.iteration_limit.to_i
      runs = 0

      # Loops until difference is within error margin
      while ((right - left).abs > Xirr::EPS && runs < limit) do

        runs += 1
        npv_positive?(midpoint) ? right = midpoint : left = midpoint
        midpoint = format_irr(left, right)

      end

      if runs >= limit
        raise ArgumentError, 'Did not converge'
      end

      return midpoint.round Xirr::PRECISION

    end

    private

    # @param midpoint [Float]
    # @return [Bolean]
    # Returns true if result is to the right ot the range
    def npv_positive?(midpoint)
      xnpv(midpoint) > 0
    end

    # @param left [Float]
    # @param right [Float]
    # @return [Float] IRR of the Cashflow
    def format_irr(left, right)
      irr = (right+left) / 2
    end

  end

end

