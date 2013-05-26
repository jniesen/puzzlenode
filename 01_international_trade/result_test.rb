require 'minitest/autorun'
require_relative 'result'

class TestRateFinder < MiniTest::Unit::TestCase
  def setup
    @rates= [
      {from: "A", to: "B", conversion: "1.5"},
      {from: "C", to: "D", conversion: "0.9"},
      {from: "A", to: "C", conversion: "0.05"}
    ]
    @rate_finder = RateFinder.new(@rates)
  end

  def test_a_currencies_conversion_rates_can_be_found
    rates_for_a = {
      B: "1.5",
      C: "0.05"
    }
    assert_equal rates_for_a, @rate_finder.find_rates_for("A")
  end

  def test_a_currencies_missing_conversion_rates_can_identified
    missing_rate_for_a = [:D]
    assert_equal missing_rate_for_a, @rate_finder.identify_missing_rate_for("A")
  end

  def test_a_strategy_for_calculating_the_missing_convesion_rate_can_be_found
    strategy = {
      step1: {from: "A", to: "C", conversion: "0.05"},
      step2: {from: "C", to: "D", conversion: "0.9"}
    }
    assert_equal strategy, @rate_finder.find_conversion_strategy("A", "D")
  end

  def test_a_currences_missing_conversion_rate_can_be_calculated
    missing_conversion_rate = "0.045"
    assert_equal missing_conversion_rate, @rate_finder.calculate_missing_rate_for("A", "D")
  end
end
