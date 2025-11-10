# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CpuBenchmark::PrimeNumberService, type: :service do
  describe '.prime?' do
    context 'with small numbers (correctness tests)' do
      it 'returns false for numbers less than 2' do
        expect(described_class.prime?(0)).to be false
        expect(described_class.prime?(1)).to be false
        expect(described_class.prime?(-5)).to be false
      end

      it 'returns true for 2' do
        expect(described_class.prime?(2)).to be true
      end

      it 'returns false for even numbers greater than 2' do
        expect(described_class.prime?(4)).to be false
        expect(described_class.prime?(10)).to be false
        expect(described_class.prime?(100)).to be false
      end

      it 'returns true for small prime numbers' do
        primes = [ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29 ]
        primes.each do |prime|
          expect(described_class.prime?(prime)).to be true
        end
      end

      it 'returns false for small composite numbers' do
        composites = [ 4, 6, 8, 9, 10, 12, 14, 15, 16, 18 ]
        composites.each do |composite|
          expect(described_class.prime?(composite)).to be false
        end
      end
    end

    context 'with large numbers (performance tests)' do
      it 'correctly identifies large prime numbers' do
        expect(described_class.prime?(104_729)).to be true # 10000th prime
        expect(described_class.prime?(1_299_709)).to be true #100000th prime
      end

      it 'correctly identifies large composite numbers' do
        expect(described_class.prime?(104_730)).to be false
        expect(described_class.prime?(1_299_710)).to be false
      end
    end
  end

  describe '.primes_up_to' do
    context 'with small numbers (correctness tests)' do
      it 'returns empty array for n < 2' do
        expect(described_class.primes_up_to(0)).to eq([])
        expect(described_class.primes_up_to(1)).to eq([])
      end

      it 'returns correct primes up to 10' do
        expect(described_class.primes_up_to(10)).to eq([2, 3, 5, 7])
      end

      it 'returns correct primes up to 30' do
        expect(described_class.primes_up_to(30)).to eq([ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29 ])
      end
    end

    context 'with large numbers (performance tests)' do
      it 'generates primes up to 100000' do
        primes = described_class.primes_up_to(100_000)
        expect(primes.size).to eq(9592) #There are 9592 primes below 100000
        expect(primes.last).to eq(99_991)
      end

      it 'generates primes up to 500000' do
        primes = described_class.primes_up_to(500_000)
        expect(primes.size).to eq(41_538) #There are 41538 primes below 500000
        expect(primes.last).to eq(499_979)
      end
    end
  end

  describe '.nth_prime' do
    context 'with edge cases' do
      it 'raises ArgumentError for n < 1' do
        expect { described_class.nth_prime(0) }.to raise_error(ArgumentError)
        expect { described_class.nth_prime(-1) }.to raise_error(ArgumentError)
      end
    end

    context 'with small numbers (correctness tests)' do
      it 'returns correct small prime numbers' do
        expect(described_class.nth_prime(1)).to eq(2)
        expect(described_class.nth_prime(2)).to eq(3)
        expect(described_class.nth_prime(3)).to eq(5)
        expect(described_class.nth_prime(4)).to eq(7)
        expect(described_class.nth_prime(5)).to eq(11)
        expect(described_class.nth_prime(10)).to eq(29)
      end
    end

    context 'with large numbers (performance tests)' do
      it 'finds the 1000th prime' do
        expect(described_class.nth_prime(1000)).to eq(7919)
      end

      it 'finds the 5000th prime' do
        expect(described_class.nth_prime(5000)).to eq(48_611)
      end

      it 'finds the 10000th prime' do
        expect(described_class.nth_prime(10_000)).to eq(104_729)
      end
    end
  end
end
