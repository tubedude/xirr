module Xirr

  # Precision for BigDecimal
  PRECISION = Xirr.config.precision.to_i
  # Days in a year
  DAYS_IN_YEAR = Xirr.config.days_in_year.to_f
  # Epsilon: error margin
  EPS = Xirr.config.eps

  #  Base module for XIRR calculation Methods
  module Base
    extend ActiveSupport::Concern
    attr_reader :cf

    # @param cf [Cashflow]
    # Must provide the calling Cashflow in order to calculate
    def initialize(cf)
      @cf = cf
    end

    # Calculates days until last transaction
    # @return [Rational]
    # @param date [Date]
    def t_in_days(date)
      (date - cf.min_date) / Xirr::DAYS_IN_YEAR
    end

  end
end
