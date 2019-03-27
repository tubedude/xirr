# frozen_string_literal: true
module Xirr
  # Methods that will be included in Cashflow to calculate XIRR
  class Bisection
    include Base

    # Calculates yearly Internal Rate of Return
    # @return [BigDecimal]
    # @param midpoint [Float]
    # An initial guess rate will override the {Cashflow#irr_guess}
    def xirr(midpoint, options)

      # Initial values
      left  = [BigDecimal(-0.99999999, Xirr::PRECISION), cf.irr_guess].min
      right = [BigDecimal(9.99999999, Xirr::PRECISION), cf.irr_guess + 1].max
      @original_right = right
      midpoint ||= cf.irr_guess

      midpoint, runs = loop_rates(left, midpoint, right, options[:iteration_limit])

      get_answer(midpoint, options, runs)

    end


    private

    # @param midpoint [BigDecimal]
    # @return [Boolean]
    # Checks if result is the right limit.
    def right_limit_reached?(midpoint)
      (@original_right - midpoint).abs < Xirr::EPS
    end

    # @param left [BigDecimal]
    # @param midpoint [BigDecimal]
    # @param right [BigDecimal]
    # @return [Array]
    # Calculates the Bisections
    def bisection(left, midpoint, right)
      _left = xnpv(left).positive?
      _mid = xnpv(midpoint).positive?
      if _left && _mid
        return left, left, left, true if xnpv(right).positive? # Not Enough Precision in the left to find the IRR
      end
      if _left == _mid
        return midpoint, format_irr(midpoint, right), right, false # Result is to the Right
      else
        return left, format_irr(left, midpoint), midpoint, false # Result is to the Left
      end
    end

    # @param left [Float]
    # @param right [Float]
    # @return [Float] IRR of the Cashflow
    def format_irr(left, right)
      irr = (right+left) / 2
    end

    def get_answer(midpoint, options, runs)
      if runs >= options[:iteration_limit]
        if options[:raise_exception]
          raise ArgumentError, "Did not converge after #{runs} tries."
        else
          nil
        end
      else
        midpoint.round Xirr::PRECISION
      end
    end

    def loop_rates(left, midpoint, right, iteration_limit)
      runs = 0
      while (right - left).abs > Xirr::EPS && runs < iteration_limit do
        runs += 1
        left, midpoint, right, should_stop = bisection(left, midpoint, right)
        break if should_stop
        if right_limit_reached?(midpoint)
          right           *= 2
          @original_right *= 2
        end
      end
      return midpoint, runs
    end
  end
end
