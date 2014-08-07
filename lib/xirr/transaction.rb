module Xirr

  # A unit of the Cashflow.
  class Transaction
    attr_reader :amount
    attr_accessor :date

    # @example
    #   Transaction.new -1000, date: Date.now
    # @param amount [Numeric]
    # @param opts [Hash]
    # @note Don't forget to add date: [Date] in the opts hash.
    def initialize(amount, opts={})
      @amount = amount.to_f

      # Set optional attributes..
      opts.each do |key, value|
        send("#{key}=", value)
      end
    end

    # Sets the amount
    # @param value [Numeric]
    # @return [Float]
    def amount=(value)
      @amount = value.to_f || 0.0
    end

    # @return [String]
    def inspect
      "T(#{@amount},#{@date})"
    end

  end

end