# frozen_string_literal: true

require_relative 'test_helper'

describe 'Transaction' do
  before(:all) do
    @t = Transaction.new(1000, date: Date.today)
  end

  it 'converts amount to float' do
    assert true, @t.amount.is_a?(Float)
  end

  it 'retreives the date' do
    assert_equal Date.today, @t.date
  end

  it 'has inspect' do
    assert_equal "T(1000.0,#{Date.today})", @t.inspect
  end
end
