# frozen_string_literal: true

module Xirr
  # A unit of the Cashflow.
  class Transaction
    attr_reader :amount, :date

    # @example
    #   Transaction.new(-1000, date: Date.new(2013, 1, 1))
    # @param amount [Numeric]
    # @param opts [Hash] must include +:date+, the date the amount falls on
    def initialize(amount, opts = {})
      self.amount = amount
      opts.each { |key, value| send("#{key}=", value) }
    end

    # Sets the date
    # @param value [Date, Time]
    # @return [Date]
    def date=(value)
      @date = value.is_a?(Time) ? value.to_date : value
    end

    # Sets the amount
    # @param value [Numeric]
    # @return [Float]
    def amount=(value)
      @amount = value.to_f
    end

    # @return [String]
    def inspect
      "T(#{@amount},#{@date})"
    end
  end
end