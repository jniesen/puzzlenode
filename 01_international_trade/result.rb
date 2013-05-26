class String
  require 'bigdecimal'
  BigDecimal.mode(BigDecimal::ROUND_MODE, BigDecimal::ROUND_HALF_EVEN)

  def to_bdec
    BigDecimal.new(self)
  end
end

class RateFinder
  def initialize(rates)
    @rates = rates
  end

  def find_rates_for(currency)
    @rates.inject({}) do |needed_rates, rate|
      needed_rates[rate[:to].to_sym] = rate[:conversion] if rate[:from] == currency
      needed_rates
    end
  end

  def identify_missing_rate_for(currency)
    available_rates = find_rates_for currency
    available_currencies.select do |blah|
      blah != currency.to_sym && !available_rates.has_key?(blah)
    end
  end

  def calculate_missing_rate_for(from_currency, to_currency)
    control = '5'.to_bdec
    strategy = find_conversion_strategy(from_currency, to_currency)
    step1_result = control * strategy[:step1][:conversion].to_bdec
    step2_result = step1_result * strategy[:step2][:conversion].to_bdec
    (step2_result / control).to_s('F')
  end

  private
  def available_currencies
    currency_array = []
    @rates.each do |rate|
      currency_array << rate[:from].to_sym
      currency_array << rate[:to].to_sym
    end
    currency_array.uniq!
  end

  def find_conversion_strategy(from_currency, to_currency)
    step1_candidates = @rates.select do |rate|
      rate[:from] == from_currency
    end

    step2_candidates = @rates.select do |rate|
      rate[:to] == to_currency
    end

    step1 = {}
    step2_candidates.each do |step2_candidate|
      step1_candidates.each do |step1_candidate|
        step1 = step1_candidate if step1_candidate[:to] == step2_candidate[:from]
      end
    end

    step2 = step2_candidates.select do |step2_candidate|
      step1[:to] == step2_candidate[:from]
    end

    {step1: step1, step2: step2.first}
  end
end

