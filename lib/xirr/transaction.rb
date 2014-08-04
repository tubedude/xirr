module Xirr

  class Transaction
    attr_reader :amount
    attr_accessor :date

    def initialize(amount, opts={})
      @amount = amount
      @original = amount

      # Set optional attributes..
      opts.each do |key, value|
        send("#{key}=", value)
      end
    end

    def amount=(value)
      @amount = value.to_f || 0
    end

    def inspect
      "T(#{@amount},#{@date})"
    end

    def description
      investment ? "#{self.investment.transaction_type_name}: #{round.description}" : @description
    end

    def round
      @investment.nil? ? nil : investment.round
    end

    def company
      @company || investment.company
    end

    def shareholder
      @shareholder || investment.shareholder
    end

  end

end