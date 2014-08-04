module Xirr

  # @abstract Expands [Array] to store a set of transactions which will be used to calculate the XIRR
  # @note A Cashflow should consist of at least two transactions, one positive and one negative.
  class Cashflow < Array
    include Xirr::Main

    # @api public
    # @param args [Transaction]
    # @example Creating a Cashflow
    #   cf = Cashflow.new
    #   cf << Transaction.new( 1000, date: '2013-01-01'.to_time(:utc))
    #   cf << Transaction.new(-1234, date: '2013-03-31'.to_time(:utc))
    #   Or
    #   cf = Cashflow.new Transaction.new( 1000, date: '2013-01-01'.to_time(:utc)), Transaction.new(-1234, date: '2013-03-31'.to_time(:utc))
    def initialize(*args) # :nodoc:
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
    def sum # :nodoc:
      self.map(&:amount).sum
    end

    # Last investment date
    # @return [Time]
    def max_date # :nodoc:
      @max_date ||= self.map(&:date).max
    end

    # Calculates a simple IRR guess based on period of investment and multiples.
    # @return [Float]
    def irr_guess
      ((multiple ** (1 / years_of_investment)) - 1).round(3)
    end

    private

    # @api private
    # Sorts the {Cashflow} by date ascending
    #   and finds the signal of the first transaction.
    # This implies the first transaction is a disembursement
    # @return [Integer]
    def first_transaction_direction
      self.sort! { |x,y| x.date <=> y.date }
      self.first.amount / self.first.amount.abs
    end

    # Based on the direction of the first investment finds the multiple cash-on-cash
    # @example
    #   [100,100,-300] and [-100,-100,300] returns 1.5
    # @api private
    # @return [Float]
    def multiple  # :nodoc:
      result = positives.sum(&:amount) / -negatives.sum(&:amount)
      first_transaction_direction > 0 ? result : 1 / result
    end

    # @api private
    # Counts how many years from first to last transaction in the cashflow
    # @return
    def years_of_investment # :nodoc:
      (max_date - min_date) / (365 * 24 * 60 * 60).to_f
    end

    # @api private
    # First investment date
    # @return [Time]
    def min_date # :nodoc:
      @min_date ||= self.map(&:date).min
    end

    # @api private
    # @return [Array]
    # @see #negatives
    # @see #split_transactions
    # Finds all transactions income from Cashflow
    def positives # :nodoc:
      split_transactions
      @positives
    end

    # @api private
    # @return [Array]
    # @see #positives
    # @see #split_transactions
    # Finds all transactions investments from Cashflow
    def negatives # :nodoc:
      split_transactions
      @negatives
    end

    # @api private
    # @see #positives
    # @see #negatives
    # Uses partition to separate the investment transactions Negatives and the income transactions (Positives)
    def split_transactions # :nodoc:
      @negatives, @positives = self.partition { |x| x.amount >= 0 } # Inverted as negative amount is good
    end

    # @api private
    # @return [String]
    # Error message depending on the missing transaction
    def invalid_message # :nodoc:
      return 'No positive transaction' if positives.empty?
      return 'No negatives transaction' if negatives.empty?
    end

  end

end
