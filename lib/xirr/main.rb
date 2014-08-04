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
      days_in_year = Xirr.config.days_in_year.to_f
      left = -0.99/days_in_year
      right = 9.99/days_in_year
      epsilon = Xirr.config.eps.to_f
      guess = self.irr_guess.to_f

      # Loops until difference is within error margin
      while ((right-left).abs > 2 * epsilon) do

        midpoint = guess || (right + left)/2
        guess = nil
        nfv_positive?(left, midpoint) ? left = midpoint : right = midpoint

      end

      return format_irr(left, right)

    end

    private

    # @param left [Float]
    # @param midpoint [Float]
    # @return [Bolean]
    # Returns true if result is to the right ot the range
    def nfv_positive?(left, midpoint)
      (nfv(left) * nfv(midpoint) > 0)
    end

    # @param left [Float]
    # @param right [Float]
    # @return [Float] IRR of the Cashflow
    def format_irr(left, right)
      days_in_year = Xirr.config.days_in_year.to_f
      # Irr for daily cashflow (not in percentage format)
      irr = (right+left) / 2
      # Irr for daily cashflow multiplied by 365 to get yearly return
      irr = irr * days_in_year
      # Annualized yield (return) reflecting compounding effect of daily returns
      irr = (1 + irr / days_in_year) ** days_in_year - 1
    end

    # Returns the Net future value of the flow given a Rate
    # @param rate [Float]
    # @return [Float]
    def nfv(rate) # :nodoc:
      self.inject(0) do |nfv,t|
        nfv = nfv + t.amount * ((1 + rate) ** t_in_days(t.date))
      end
    end

    # Calculates days until last transaction
    # @return [Rational]
    # @param date [Time]
    def t_in_days(date)
      Date.parse(max_date.to_s) - Date.parse(date.to_s)
    end

  end

end

