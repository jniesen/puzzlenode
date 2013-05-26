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

