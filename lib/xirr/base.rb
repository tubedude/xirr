# frozen_string_literal: true
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
    def periods_from_start(date)
      (date - cf.min_date) / cf.period
    end

    # Net Present Value function that will be used to reduce the cashflow
    # @param rate [BigDecimal]
    # @return [BigDecimal]
    def xnpv(rate)
      cf.inject(0) do |sum, t|
        sum + (xnpv_c rate, t.amount, periods_from_start(t.date))
      end
    end

    inline do |builder|
      builder.include '<math.h>'
      builder.c '
        double xnpv_c(double rate, double amount, double period) {
          return amount / pow(1 + rate, period);
        }'
    end
  end
end
