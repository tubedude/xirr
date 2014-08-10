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
      left = [BigDecimal.new(-0.99, Xirr::PRECISION), cf.irr_guess].min
      right = [BigDecimal.new(9.99, Xirr::PRECISION), cf.irr_guess + 1].max
      midpoint ||= cf.irr_guess
      runs = 0

      # Loops until difference is within error margin
      while ((right - left).abs > Xirr::EPS && runs < Xirr.config.iteration_limit.to_i) do

        runs += 1
        left, midpoint, right = bisection(left, midpoint, right)

      end

      if runs >= Xirr.config.iteration_limit.to_i
        raise ArgumentError, "Did not converge after #{runs} tries."
      end

      # If enabled, will retry XIRR with NewtonMethod
      if Xirr::FALLBACK && right_limit_reached?(midpoint, cf.irr_guess + 1)
        return NewtonMethod.new(cf).xirr
      end

      return midpoint.round Xirr::PRECISION

    end

    private

    # @param right [BigDecimal]
    # @param midpoint [BigDecimal]
    # @return [Boolean]
    # Checks if result is the right limit.
    def right_limit_reached?(midpoint, original_right)
      (original_right - midpoint).abs < Xirr::EPS
    end

    # @param left [BigDecimal]
    # @param midpoint [BigDecimal]
    # @param right [BigDecimal]
    # @return [Array]
    # Calculates the Bisections
    def bisection(left, midpoint, right)
      _left, _mid = npv_positive?(left), npv_positive?(midpoint)
      if _left && _mid
        return left, left, left if npv_positive?(right) # Not Enough Precision in the left to find the IRR
      end
      if _left == _mid
        return midpoint, format_irr(midpoint, right), right # Result is to the Right
      else
        return left, format_irr(left, midpoint), midpoint # Result is to the Left
      end
    end

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

