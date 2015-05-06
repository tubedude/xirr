module Xirr

  # Expands [Array] to store a set of transactions which will be used to calculate the XIRR
  # @note A Cashflow should consist of at least two transactions, one positive and one negative.
  class Cashflow < Array
    attr_reader :raise_exception, :fallback, :iteration_limit, :options

    # @param args [Transaction]
    # @example Creating a Cashflow
    #   cf = Cashflow.new
    #   cf << Transaction.new( 1000, date: '2013-01-01'.to_date)
    #   cf << Transaction.new(-1234, date: '2013-03-31'.to_date)
    #   Or
    #   cf = Cashflow.new Transaction.new( 1000, date: '2013-01-01'.to_date), Transaction.new(-1234, date: '2013-03-31'.to_date)
    def initialize(flow: [], period: Xirr::PERIOD, ** options)
      @period   = period
      @fallback = options[:fallback] || Xirr::FALLBACK
      @options  = options
      self << flow
      self.flatten!
    end

    # Check if Cashflow is invalid
    # @return [Boolean]
    def invalid?
      inflow.empty? || outflows.empty?
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
      return @irr_guess = 0.0 if periods_of_investment.zero?
      @irr_guess = valid? ? ((multiple ** (1 / periods_of_investment)) - 1).round(3) : false
      @irr_guess == 1.0/0 ? 0.0 : @irr_guess
    end

    # @param guess [Float]
    # @param method [Symbol]
    # @return [Float]
    def xirr(guess: nil, method: nil, ** options)
      method, options = process_options(method, options)
      if invalid?
        raise ArgumentError, invalid_message if options[:raise_exception]
        BigDecimal.new(0, Xirr::PRECISION)
      else
        xirr = choose_(method).send :xirr, guess, options
        xirr = choose_(other_calculation_method(method)).send(:xirr, guess, options) if (xirr.nil? || xirr.nan?) && fallback
        xirr || Xirr::REPLACE_FOR_NIL
      end
    end

    def process_options(method, options)
      @temporary_period         = options[:period]
      options[:raise_exception] ||= @options[:raise_exception] || Xirr::RAISE_EXCEPTION
      options[:iteration_limit] ||= @options[:iteration_limit] || Xirr::ITERATION_LIMIT
      return switch_fallback(method), options
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
      Cashflow.new flow: compact.map { |key, value| Transaction.new(value, date: key) }, options: options, period: period
    end

    # First investment date
    # @return [Time]
    def min_date
      @min_date ||= self.map(&:date).min
    end

    # @return [String]
    # Error message depending on the missing transaction
    def invalid_message
      return 'No positive transaction' if inflow.empty?
      return 'No negative transaction' if outflows.empty?
    end

    def period
      @temporary_period || @period
    end

    def << arg
      super arg
      self.sort! { |x, y| x.date <=> y.date }
      self
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
      # self.sort! { |x, y| x.date <=> y.date }
      @first_transaction_direction ||= self.first.amount / self.first.amount.abs
    end

    # Based on the direction of the first investment finds the multiple cash-on-cash
    # @example
    #   [100,100,-300] and [-100,-100,300] returns 1.5
    # @api private
    # @return [Float]
    def multiple
      inflow.sum(&:amount).abs / outflows.sum(&:amount).abs
    end

    def first_transaction_positive?
      first_transaction_direction > 0
    end

    # @api private
    # Counts how many years from first to last transaction in the cashflow
    # @return
    def periods_of_investment
      (max_date - min_date) / period
    end

    # @api private
    # @return [Array]
    # @see #outflows
    # Selects all positives transactions from Cashflow
    def inflow
      self.select { |x| x.amount * first_transaction_direction < 0 }
    end

    # @api private
    # @return [Array]
    # @see #inflow
    # Selects all negatives transactions from Cashflow
    def outflows
      self.select { |x| x.amount * first_transaction_direction > 0 }
    end

  end

end
