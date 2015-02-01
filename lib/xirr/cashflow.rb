module Xirr

  # Expands [Array] to store a set of transactions which will be used to calculate the XIRR
  # @note A Cashflow should consist of at least two transactions, one positive and one negative.
  class Cashflow < Array
    attr_reader :period, :raise_exception

    # @param args [Transaction]
    # @example Creating a Cashflow
    #   cf = Cashflow.new
    #   cf << Transaction.new( 1000, date: '2013-01-01'.to_date)
    #   cf << Transaction.new(-1234, date: '2013-03-31'.to_date)
    #   Or
    #   cf = Cashflow.new Transaction.new( 1000, date: '2013-01-01'.to_date), Transaction.new(-1234, date: '2013-03-31'.to_date)
    def initialize(flow: [], period: Xirr::PERIOD, ** options)
      @period   = period
      @fallback = options[:fallback]
      @options  = options
      flow.each { |a| self << a }
      self.flatten!
    end

    def compactable?
      self.count < uniq_dates.count
    end

    def uniq_dates
      @uniq_dates ||= self.map(&:date).uniq
    end

    # Check if Cashflow is invalid
    # @return [Boolean]
    def invalid?
      positives.empty? || negatives.empty?
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

    def fallback
      if @fallback.nil?
        Xirr::FALLBACK
      else
        @fallback
      end
    end

    # Calculates a simple IRR guess based on period of investment and multiples.
    # @return [Float]
    def irr_guess
      return @irr_guess = 0.0 if periods_of_investment.zero?
      @irr_guess = valid? ? ((multiple ** (1 / periods_of_investment)) - 1).round(3) : false
      @irr_guess == 1.0/0 ? 0.0 : @irr_guess
    end

    # @param guess [Float]
    # @param method [Symbol]
    # @return [Float]
    def xirr(guess: nil, method: nil, raise_exception: Xirr::RAISE_EXCEPTION)
      method           = switch_fallback method
      @raise_exception = raise_exception
      if invalid?
        raise ArgumentError, invalid_message if raise_exception
        BigDecimal.new(0, Xirr::PRECISION)
      else
        xirr = choose_(method).send :xirr, guess
        xirr = choose_(other_calculation_method(method)).send(:xirr, guess) if xirr.nil? && fallback
        xirr.nil? ? Xirr::REPLACE_FOR_NIL : xirr
      end
    end

    # If method is defined it will turn off fallback
    # it return either the provided method or the system default
    # @param method [Symbol]
    # @return [Symbol]
    def switch_fallback method
      if method
        @fallback = false
        method
      else
        @fallback = Xirr::FALLBACK
        Xirr::DEFAULT_METHOD
      end
    end

    def other_calculation_method(method)
      method == :newton_method ? :bisection : :newton_method
    end

    def compact_cf
      # self
      compact = Hash.new 0
      self.each { |flow| compact[flow.date] += flow.amount }
      Cashflow.new flow: compact.map { |key, value| Transaction.new(value, date: key) }, period: period, options: @options
    end

    # First investment date
    # @return [Time]
    def min_date
      @min_date ||= self.map(&:date).min
    end

    # @return [String]
    # Error message depending on the missing transaction
    def invalid_message
      return 'No positive transaction' if positives.empty?
      return 'No negative transaction' if negatives.empty?
    end

    private

    # @param method [Symbol]
    # Choose a Method to call.
    # @return [Class]
    def choose_(method)
      case method
        when :bisection
          Bisection.new compact_cf
        when :newton_method
          NewtonMethod.new compact_cf
        else
          raise ArgumentError, "There is no method called #{method} "
      end
    end

    # @api private
    # Sorts the {Cashflow} by date ascending
    #   and finds the signal of the first transaction.
    # This implies the first transaction is a disbursement
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
    def periods_of_investment
      (max_date - min_date) / period
    end

    # @api private
    # @return [Array]
    # @see #negatives
    # Selects all positives transactions from Cashflow
    def positives
      return @positives if @positives
      @positives, @negatives = self.partition { |x| x.amount < 0 }
      @positives
    end

    # @api private
    # @return [Array]
    # @see #positives
    # Selects all negatives transactions from Cashflow
    def negatives
      return @negatives if @negatives
      @negatives, @positives= self.partition { |x| x.amount > 0 }
      @negatives
    end

  end

end
