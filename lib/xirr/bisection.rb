# frozen_string_literal: true

module Xirr
  # Bisection solver: repeatedly halves a bracket that straddles the root. It
  # always converges on a bracketed flow but only linearly, so it is slower than
  # {RtSafe}, which is the default. Kept for `xirr(method: :bisection)`.
  class Bisection
    include Base

    # Calculates yearly Internal Rate of Return
    # @return [Float]
    # @param midpoint [Float]
    # An initial guess rate will override the {Cashflow#irr_guess}
    def xirr(midpoint, options)
      # Initial values
      left  = [-0.99999999, cf.irr_guess].min
      right = [9.99999999, cf.irr_guess + 1].max
      @original_right = right
      midpoint ||= cf.irr_guess

      midpoint, runs = loop_rates(left, midpoint, right, options[:iteration_limit])

      get_answer(midpoint, options, runs)
    end

    private

    # @param midpoint [Float]
    # @return [Boolean]
    # Checks if result is the right limit.
    def right_limit_reached?(midpoint)
      (@original_right - midpoint).abs < Xirr.config.eps
    end

    # @param left [Float]
    # @param midpoint [Float]
    # @param right [Float]
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
      irr = (right + left) / 2
    end

    def get_answer(midpoint, options, runs)
      if runs >= options[:iteration_limit]
        raise ArgumentError, "Did not converge after #{runs} tries." if options[:raise_exception]

        nil
      else
        answer = midpoint.round(Xirr.config.precision)
        # A midpoint parked at the -100% floor means no root was bracketed.
        answer <= -1 ? nil : answer
      end
    end

    def loop_rates(left, midpoint, right, iteration_limit)
      runs = 0
      while (right - left).abs > Xirr.config.eps && runs < iteration_limit do
        runs += 1
        left, midpoint, right, should_stop = bisection(left, midpoint, right)
        break if should_stop
        if right_limit_reached?(midpoint)
          right           *= 2
          @original_right *= 2
        end
      end
      [midpoint, runs]
    end
  end
end
