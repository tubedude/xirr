module Xirr

  # Expands [Array] to store a set of transactions which will be used to calculate the XIRR
  # @note A Cashflow should consist of at least two transactions, one positive and one negative.
  class Cashflow < Array

    # @param args [Transaction]
    # @example Creating a Cashflow
    #   cf = Cashflow.new
    #   cf << Transaction.new( 1000, date: '2013-01-01'.to_date)
    #   cf << Transaction.new(-1234, date: '2013-03-31'.to_date)
    #   Or
    #   cf = Cashflow.new Transaction.new( 1000, date: '2013-01-01'.to_date), Transaction.new(-1234, date: '2013-03-31'.to_date)
    def initialize(*args)
      args.each { |a| self << a }
      self.flatten!
    end

    # Check if Cashflow is invalid and raises ArgumentError
    # @return [Boolean]
    def invalid?
      if positives.empty? || negatives.empty?
        raise ArgumentError, invalid_message
      else
        false
      end
    end

    # Inverse of #invalid?
    # @return [Boolean]
    def valid?
      !invalid?
    end

    # @return [Float]
    # Sums all amounts in a cashflow
    def sum
      self.map(&:amount).sum
    end

    # Last investment date
    # @return [Time]
    def max_date
      @max_date ||= self.map(&:date).max
    end

    # Calculates a simple IRR guess based on period of investment and multiples.
    # @return [Float]
    def irr_guess
      ((multiple ** (1 / years_of_investment)) - 1).round(3) if valid?
    end

    # @param guess [Float]
    # @param method [Symbol]
    # @return [Float]
    # Finds the XIRR according to the method provided. Default to Bisection
    def xirr(guess = nil, method = Xirr.config.default_method)
      _method = if method == :bisection
                  Bisection.new(self)
                else
                  NewtonMethod.new(self)
                end
      _method.send :xirr, guess if valid?
    end

    # First investment date
    # @return [Time]
    def min_date
      @min_date ||= self.map(&:date).min
    end

    private

    # @api private
    # Sorts the {Cashflow} by date ascending
    #   and finds the signal of the first transaction.
    # This implies the first transaction is a disembursement
    # @return [Integer]
    def first_transaction_direction
      self.sort! { |x, y| x.date <=> y.date }
      self.first.amount / self.first.amount.abs
    end

    # Based on the direction of the first investment finds the multiple cash-on-cash
    # @example
    #   [100,100,-300] and [-100,-100,300] returns 1.5
    # @api private
    # @return [Float]
    def multiple
      result = positives.sum(&:amount) / -negatives.sum(&:amount)
      first_transaction_direction > 0 ? result : 1 / result
    end

    # @api private
    # Counts how many years from first to last transaction in the cashflow
    # @return
    def years_of_investment
      (max_date - min_date) / (365).to_f
    end

    # @api private
    # @return [Array]
    # @see #negatives
    # @see #split_transactions
    # Finds all transactions income from Cashflow
    def positives
      split_transactions
      @positives
    end

    # @api private
    # @return [Array]
    # @see #positives
    # @see #split_transactions
    # Finds all transactions investments from Cashflow
    def negatives
      split_transactions
      @negatives
    end

    # @api private
    # @see #positives
    # @see #negatives
    # Uses partition to separate the investment transactions Negatives and the income transactions (Positives)
    def split_transactions
      @negatives, @positives = self.partition { |x| x.amount >= 0 } # Inverted as negative amount is good
    end

    # @api private
    # @return [String]
    # Error message depending on the missing transaction
    def invalid_message
      return 'No positive transaction' if positives.empty?
      return 'No negative transaction' if negatives.empty?
    end

  end

end
