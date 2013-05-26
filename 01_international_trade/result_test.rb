require 'minitest/autorun'
require_relative 'result'

class TestRateFinder < MiniTest::Unit::TestCase
  def setup
    @rates = [
      {from: 'A', to: 'B', conversion: '1.5'},
      {from: 'C', to: 'D', conversion: '0.9'},
      {from: 'A', to: 'C', conversion: '0.05'}
    ]
    @rate_finder = RateFinder.new(@rates)
  end

  def test_can_return_a_conversion_rate_for_in_pocket_currency_and_desired_currency
    assert_equal '1.5', @rate_finder.get_conversion_rate_for('A', 'B')
  end

  def test_a_currenceis_missing_conversion_rate_can_be_calculated
    missing_conversion_rate = '0.045'
    assert_equal missing_conversion_rate, @rate_finder.calculate_missing_rate_for('A', 'D')
  end

  def test_can_store_a_calculated_conversion_rate_between_currencies
    rates_size_before = @rates.size
    @rate_finder.calculate_missing_rate_for('A', 'D')
    assert_equal rates_size_before + 1, @rates.size

  end

  def test_can_return_a_calculated_conversion_rate_between_currencies
    assert_equal '0.045', @rate_finder.get_conversion_rate_for('A', 'D')
  end
end
