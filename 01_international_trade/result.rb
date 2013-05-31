class String
  require 'bigdecimal'
  BigDecimal.mode(BigDecimal::ROUND_MODE, BigDecimal::ROUND_HALF_EVEN)

  def to_bdec
    BigDecimal.new(self)
  end
end

class Float
  require 'bigdecimal'
  BigDecimal.mode(BigDecimal::ROUND_MODE, BigDecimal::ROUND_HALF_EVEN)

  def to_bdec
    BigDecimal.new(self.to_s)
  end
end

class RateFinder
  def initialize(rates)
    @rates = rates
  end

  def get_conversion_rate_for(from, to)
    matches = @rates.select do |rate|
      rate.values_at(:from, :to) == [from, to]
    end

    rate = matches.first && matches.first[:conversion]
    rate ||= calculate_missing_rate_for(from, to)
  end

  def calculate_missing_rate_for(from, to)
    control = '5'.to_bdec
    strategy = find_conversion_strategy(from, to)

    step1_result = control * strategy[:step1][:conversion].to_bdec
    step2_result = step1_result * strategy[:step2][:conversion].to_bdec
    conversion_rate = (step2_result / control).to_s('F')
    @rates << {from: from, to: to, conversion: conversion_rate }
    conversion_rate
  end

  private
  def find_conversion_strategy(from, to)
    step1_candidates = @rates.select { |rate| rate[:from] == from }
    step2_candidates = @rates.select { |rate| rate[:to] == to }

    step1 = {}
    step2_candidates.each do |step2_candidate|
      step1_candidates.each do |step1_candidate|
        step1 = step1_candidate if step1_candidate[:to] == step2_candidate[:from]
      end
    end

    step2 = step2_candidates.select { |candidate| step1[:to] == candidate[:from] }

    {step1: step1, step2: step2.first}
  end
end

class InternationalTotaler
  def initialize(totals)
    @totals = totals
  end

  def totals_for_sku(sku)
    location_totals = @totals.select { |total| total[:sku] == sku }
    location_totals.map() do |total|
      {total: total[:total], currency: total[:currency]}
    end
  end

  def get_totals(rates, desired_currency, transactions)
    transactions.map do |transaction|
      if transaction[:currency] != desired_currency
        conversion_rate = rates.get_conversion_rate_for(transaction[:currency], desired_currency).to_bdec
        new_total = transaction[:total].to_bdec * conversion_rate
        transaction[:total] = new_total.to_s('F')
        transaction[:currency] = desired_currency
      end
    end
    transactions.inject(0) do |total, transaction|
      total.to_s.to_bdec + transaction[:total].to_bdec
    end.to_s('F')
  end
end


class Runner
  require 'csv'
  require 'bundler/setup'
  require 'nori'

  RATES_FILE = File.open('files/RATES.xml').read
  TRANS_FILE = 'files/SAMPLE_TRANS.csv'

  def self.run
    symbols = lambda { |tag| tag.to_sym }
    parsed_xml = Nori.new(convert_tags_to: symbols).parse(RATES_FILE)

    rates = parsed_xml[:rates][:rate]
    rate_finder = RateFinder.new(rates)

    transactions = CSV.read(TRANS_FILE)
    columns = transactions.delete_at(0)
    transactions = transactions.map { |a| Hash[ columns.zip(a) ] }
  end
end

Runner.run

