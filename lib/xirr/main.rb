require 'active_support/concern'

module Xirr

  # Methods that will be included in Cashflow to calculate XIRR
  module Main
    extend ActiveSupport::Concern

    # Calculates yearly Internal Rate of Return
    # @return [Float]
    # @param guess [Float] an initial guess rate that will override the {Cashflow#irr_guess}
    def xirr(guess = nil)

      # Raises error if Cashflow is not valid
      self.valid?

      # Bisection method finding the rate to zero nfv

      # Initial values
      left = -0.99
      right = 9.99
      epsilon = Xirr.config.eps.to_f
      guess = self.irr_guess.to_f

      # Loops until difference is within error margin
      while ((right-left).abs > 2 * epsilon) do

        midpoint = guess || (right + left)/2
        guess = nil
        npv_positive?(midpoint) ? right = midpoint : left = midpoint

      end

      return format_irr left, right

    end

    private

    # @param midpoint [Float]
    # @return [Bolean]
    # Returns true if result is to the left ot the range
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
      self.inject(0) do |npv, t|
        npv += t.amount * ((1 + rate) ** t_in_days(t.date))
      end
    end

    # Calculates days until last transaction
    # @return [Rational]
    # @param date [Time]
    def t_in_days(date)
      (Date.parse(max_date.to_s) - Date.parse(date.to_s)) / Xirr.config.days_in_year.to_f
    end

  end

end

