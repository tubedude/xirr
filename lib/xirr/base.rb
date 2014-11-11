module Xirr

  #  Base module for XIRR calculation Methods
  module Base
    extend ActiveSupport::Concern
    require 'inline'
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

    # Net Present Value funtion that will be used to reduce the cashflow
    # @param rate [BigDecimal]
    # @return [BigDecimal]
    def xnpv(rate)
      cf.inject(0) do |sum, t|
        # sum += t.amount / (1 + rate) ** t_in_days(t.date)
        sum += xnpv_c rate, t.amount, t_in_days(t.date)
      end
    end

    inline { |builder|
      builder.include "<math.h>"
      builder.c "
        double xnpv_c(double rate, double amount, double days) {
          return amount / pow(1 + rate, days);
        }"
    }

  end
end
