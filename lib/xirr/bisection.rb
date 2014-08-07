module Xirr

  # Methods that will be included in Cashflow to calculate XIRR
  class Bisection
    include Base

    # Calculates yearly Internal Rate of Return
    # @return [BigDecimal]
    # @param midpoint [Float]
    # An initial guess rate will override the {Cashflow#irr_guess}
    def xirr(midpoint = nil)

      # Raises error if Cashflow is not valid
      cf.valid?

      # Bisection method finding the rate to zero nfv

      # Initial values
      left = BigDecimal.new -0.99, Xirr::PRECISION
      right = BigDecimal.new 9.99, Xirr::PRECISION
      eps = Xirr::EPS
      midpoint ||= cf.irr_guess
      limit = Xirr.config.iteration_limit.to_i
      runs = 0

      # Loops until difference is within error margin
      while ((right-left).abs > eps) do

        raise 'Did not converge' if runs == limit
        runs += 1
        npv_positive?(midpoint) ? right = midpoint : left = midpoint
        midpoint = format_irr(left, right)

      end

      return midpoint

    end

    private

    # @param midpoint [Float]
    # @return [Bolean]
    # Returns true if result is to the right ot the range
    def npv_positive?(midpoint)
      npv(midpoint) > 0
    end

    # @param left [Float]
    # @param right [Float]
    # @return [Float] IRR of the Cashflow
    def format_irr(left, right)
      irr = (right+left) / 2
    end

    # Returns the Net Present Value of the flow given a Rate
    # @param rate [Float]
    # @return [Float]
    def npv(rate) # :nodoc:
      cf.inject(0) do |npv, t|
        npv += t.amount / (1 + rate) ** t_in_days(t.date)
      end
    end

  end

end

