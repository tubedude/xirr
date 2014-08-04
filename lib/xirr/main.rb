require 'active_support/concern'

module Xirr

  module Main
    extend ActiveSupport::Concern

    # Calculates yearly Internal Rate of Return
    # returns [Float]
    def xirr(guess = nil)

      self.valid?

      # Bisection method finding the rate to zero nfv

      days_in_year = Xirr.config.days_in_year.to_f

      left = -0.99/days_in_year
      right = 9.99/days_in_year
      epsilon = Xirr.config.eps.to_f

      guess = self.irr_guess.to_f

      while ((right-left).abs > 2 * epsilon) do

        midpoint = guess || (right + left)/2
        guess = nil

        if (nfv(left) * nfv(midpoint) > 0)

          left = midpoint

        else

          right = midpoint

        end

      end

      # Irr for daily cashflow (not in percentage format)
      irr = (right+left) / 2
      # Irr for daily cashflow multiplied by 365 to get yearly return
      irr = irr * days_in_year
      # Annualized yield (return) reflecting compounding effect of daily returns
      irr = (1 + irr / days_in_year) ** days_in_year - 1

      return irr

    end

    private

    def nfv(rate) # :nodoc:

      today = self.map(&:date).max.to_date
      nfv = 0
      self.each do |t|
        cf, date = t.amount, t.date

        datestring = date.to_s
        formatteddate = Date.parse(datestring).to_date
        t_in_days = (today - formatteddate).numerator / (today - formatteddate).denominator
        nfv = nfv + cf * ((1 + rate) ** t_in_days)

      end
      return nfv

    end

  end

end

