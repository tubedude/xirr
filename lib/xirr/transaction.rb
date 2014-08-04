module Xirr

  # @abstract A unit of the Cashflow.
  class Transaction
    attr_reader :amount
    attr_accessor :date

    # @example
    #   Transaction.new -1000, date: Time.now
    def initialize(amount, opts={})
      @amount = amount
      @original = amount

      # Set optional attributes..
      opts.each do |key, value|
        send("#{key}=", value)
      end
    end

    # Sets the amount
    # @param value [Float, Integer]
    # @return [Float]
    def amount=(value)
      @amount = value.to_f || 0
    end

    # @return [String]
    def inspect
      "T(#{@amount},#{@date})"
    end

  end

end