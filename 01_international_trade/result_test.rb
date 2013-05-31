require 'minitest/unit'
require 'bigdecimal'
require 'ostruct'
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

class TestInternationalTotaler < MiniTest::Unit::TestCase
  def setup
    international_totals = [
      {store: 'Scranton', sku: 'B5', total: 5.00, currency: 'USD'},
      {store: 'Scranton', sku: 'A7', total: 10.00, currency: 'USD'},
      {store: 'Nashua', sku: 'B5', total: 7.00, currency: 'AUD'}
    ]
    @international_totaler = InternationalTotaler.new(international_totals)
  end

  def test_can_return_the_totals_and_currency_at_each_location_for_a_given_sku
    location_totals = [
      {total: 5.00, currency: 'USD'},
      {total: 7.00, currency: 'AUD'}
    ]
    assert_equal location_totals, @international_totaler.totals_for_sku('B5')
  end

  def test_can_convert_the_totals_to_the_given_currency
    rate_finder = MiniTest::Mock.new
    rate_finder.expect(:get_conversion_rate_for, "1.0169711", ['AUD', 'USD'])
    location_totals = [
      {total: 5.00, currency: 'USD'},
      {total: 7.00, currency: 'AUD'}
    ]
    assert_equal "12.1187977", @international_totaler.get_totals(rate_finder, 'USD', location_totals)
  end
end
